#!/bin/bash
# ==========================================
# Módulo: Motor Nativo BHTTP v1 + WebSocket (Puerto 8080)
# Compatible con UltraCustom, HTTP Custom y Ubuntu 22/24/26
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

BHTTP_DIR="/etc/vps-manager/bhttp"
BHTTP_PORT=8080
SSH_PORT=22

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   INSTALADOR MOTOR BHTTP v1 PRO (PUERTO 8080)  ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}[+] Preparando entorno y liberando puerto $BHTTP_PORT...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y python3 iptables net-tools psmisc ufw >/dev/null 2>&1

systemctl stop bhttp.service >/dev/null 2>&1
fuser -k ${BHTTP_PORT}/tcp >/dev/null 2>&1

mkdir -p "$BHTTP_DIR"

echo -e "${C_YELLOW}[+] Compilando núcleo BHTTP v1 (Dual-Stream + Payload)...${C_NC}"

cat << 'EOF' > "$BHTTP_DIR/bhttp_tunnel.py"
#!/usr/bin/env python3
import socket
import threading
import select
import time
import sys

LISTEN_HOST = '0.0.0.0'
LISTEN_PORT = 8080
SSH_HOST = '127.0.0.1'
SSH_PORT = 22
BUFFER_SIZE = 65535

# Diccionario de sesiones para emparejar canales GET/POST de BHTTP v1
SESSIONS = {}
SESSIONS_LOCK = threading.Lock()

def connect_ssh():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    s.connect((SSH_HOST, SSH_PORT))
    return s

def bridge_bidirectional(sock1, sock2):
    sockets = [sock1, sock2]
    try:
        while True:
            r, _, e = select.select(sockets, [], sockets, 60)
            if e or not r:
                break
            for s in r:
                data = s.recv(BUFFER_SIZE)
                if not data:
                    return
                if s is sock1:
                    sock2.sendall(data)
                else:
                    sock1.sendall(data)
    except Exception:
        pass
    finally:
        for s in sockets:
            try:
                s.close()
            except Exception:
                pass

def pipe_unidirectional(src, dst, is_chunked=False):
    """Pasa datos de una conexión a otra (soporta decodificación chunked para BHTTP v1)"""
    try:
        if not is_chunked:
            while True:
                data = src.recv(BUFFER_SIZE)
                if not data:
                    break
                dst.sendall(data)
        else:
            buf = b""
            while True:
                while b"\r\n" not in buf:
                    chunk = src.recv(BUFFER_SIZE)
                    if not chunk:
                        return
                    buf += chunk
                line, buf = buf.split(b"\r\n", 1)
                line_str = line.split(b";")[0].strip()
                if not line_str:
                    continue
                try:
                    length = int(line_str, 16)
                except ValueError:
                    # Si no es hexadecimal válido, enviamos crudo
                    dst.sendall(line + b"\r\n" + buf)
                    buf = b""
                    while True:
                        c = src.recv(BUFFER_SIZE)
                        if not c:
                            return
                        dst.sendall(c)
                if length == 0:
                    break
                while len(buf) < length + 2:
                    chunk = src.recv(BUFFER_SIZE)
                    if not chunk:
                        return
                    buf += chunk
                payload = buf[:length]
                buf = buf[length + 2:]
                dst.sendall(payload)
    except Exception:
        pass
    finally:
        try:
            src.close()
        except Exception:
            pass

def get_session_key(client_ip, path, headers):
    # Buscar encabezados de sesión usados por clientes BHTTP v1
    for k in ('x-session-id', 'x-id', 'x-bhttp-id', 'x-stream-id', 'id', 'session', 'token', 'cookie'):
        if k in headers:
            return f"{client_ip}_{headers[k]}"
    if path and path != "/":
        return f"{client_ip}_{path}"
    return f"{client_ip}_default"

def cleanup_sessions():
    while True:
        time.sleep(30)
        now = time.time()
        with SESSIONS_LOCK:
            expired = [k for k, v in SESSIONS.items() if now - v['ts'] > 120]
            for k in expired:
                try:
                    SESSIONS[k]['ssh'].close()
                except Exception:
                    pass
                del SESSIONS[k]

def handle_client(client_sock, addr):
    client_ip = addr[0]
    try:
        client_sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        client_sock.settimeout(15)

        data = b""
        while b"\r\n\r\n" not in data:
            chunk = client_sock.recv(BUFFER_SIZE)
            if not chunk:
                client_sock.close()
                return
            data += chunk
            # Si es conexión SSH directa sin HTTP
            if data.startswith(b"SSH-") or len(data) > 16384:
                break

        client_sock.settimeout(None)

        # 1. Conexión SSH directa
        if data.startswith(b"SSH-"):
            ssh_sock = connect_ssh()
            ssh_sock.sendall(data)
            bridge_bidirectional(client_sock, ssh_sock)
            return

        if b"\r\n\r\n" not in data:
            ssh_sock = connect_ssh()
            ssh_sock.sendall(data)
            bridge_bidirectional(client_sock, ssh_sock)
            return

        header_bytes, body = data.split(b"\r\n\r\n", 1)
        header_text = header_bytes.decode('latin-1', errors='ignore')
        lines = header_text.split("\r\n")
        first_line = lines[0].split(" ")
        method = first_line[0].upper() if len(first_line) > 0 else "GET"
        path = first_line[1] if len(first_line) > 1 else "/"

        headers = {}
        for line in lines[1:]:
            if ":" in line:
                k, v = line.split(":", 1)
                headers[k.strip().lower()] = v.strip()

        is_chunked = "chunked" in headers.get("transfer-encoding", "").lower()
        is_websocket = "upgrade" in headers.get("connection", "").lower() or "websocket" in headers.get("upgrade", "").lower()

        # 2. Modo BHTTP v1 Dual-Connection (Cuando la app envía un canal POST/PUT de subida)
        if method in ("POST", "PUT") and not is_websocket and not body.startswith(b"SSH-"):
            sess_key = get_session_key(client_ip, path, headers)
            with SESSIONS_LOCK:
                if sess_key not in SESSIONS:
                    SESSIONS[sess_key] = {'ssh': connect_ssh(), 'ts': time.time()}
                ssh_sock = SESSIONS[sess_key]['ssh']
                SESSIONS[sess_key]['ts'] = time.time()

            # Algunos clientes BHTTP esperan 200 OK al abrir el stream POST
            client_sock.sendall(
                b"HTTP/1.1 200 OK\r\n"
                b"Connection: keep-alive\r\n"
                b"Cache-Control: no-cache\r\n\r\n"
            )
            if body:
                ssh_sock.sendall(body)
            pipe_unidirectional(client_sock, ssh_sock, is_chunked)
            return

        # 3. Verificar si este GET pertenece a una sesión BHTTP v1 ya creada por un POST
        sess_key = get_session_key(client_ip, path, headers)
        existing_ssh = None
        with SESSIONS_LOCK:
            if sess_key in SESSIONS:
                existing_ssh = SESSIONS[sess_key]['ssh']
                SESSIONS[sess_key]['ts'] = time.time()

        if existing_ssh and not is_websocket:
            client_sock.sendall(
                b"HTTP/1.1 200 OK\r\n"
                b"Content-Type: application/octet-stream\r\n"
                b"Connection: keep-alive\r\n"
                b"Cache-Control: no-cache\r\n\r\n"
            )
            if body:
                existing_ssh.sendall(body)
            # Leemos bidireccionalmente por si el POST aún no llega o ya está inyectando en existing_ssh
            bridge_bidirectional(client_sock, existing_ssh)
            return

        # 4. Modo BHTTP Single-Stream o Payload / WebSocket
        with SESSIONS_LOCK:
            ssh_sock = connect_ssh()
            SESSIONS[sess_key] = {'ssh': ssh_sock, 'ts': time.time()}

        if is_websocket:
            client_sock.sendall(
                b"HTTP/1.1 101 Switching Protocols\r\n"
                b"Upgrade: websocket\r\n"
                b"Connection: Upgrade\r\n\r\n"
            )
        else:
            # Respuesta estándar 200 OK exigida por BHTTP v1
            client_sock.sendall(
                b"HTTP/1.1 200 OK\r\n"
                b"Content-Type: application/octet-stream\r\n"
                b"Connection: keep-alive\r\n"
                b"Cache-Control: no-cache\r\n\r\n"
            )

        if body:
            if b"SSH-" in body:
                idx = body.find(b"SSH-")
                ssh_sock.sendall(body[idx:])
            else:
                ssh_sock.sendall(body)

        bridge_bidirectional(client_sock, ssh_sock)

    except Exception:
        try:
            client_sock.close()
        except Exception:
            pass

def main():
    cleaner = threading.Thread(target=cleanup_sessions, daemon=True)
    cleaner.start()

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server.bind((LISTEN_HOST, LISTEN_PORT))
        server.listen(1024)
        print(f"[*] Motor BHTTP v1 activo en {LISTEN_HOST}:{LISTEN_PORT} -> {SSH_HOST}:{SSH_PORT}")
    except Exception as e:
        print(f"[!] Error al enlazar puerto {LISTEN_PORT}: {e}")
        sys.exit(1)

    while True:
        try:
            client_sock, addr = server.accept()
            t = threading.Thread(target=handle_client, args=(client_sock, addr), daemon=True)
            t.start()
        except KeyboardInterrupt:
            break
        except Exception:
            continue

if __name__ == '__main__':
    main()
EOF

chmod +x "$BHTTP_DIR/bhttp_tunnel.py"

# Reglas de Firewall para el puerto 8080
iptables -D INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT 2>/dev/null
iptables -I INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
ufw allow ${BHTTP_PORT}/tcp >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Activando servicio Systemd BHTTP v1...${C_NC}"
cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=Golbert BHTTP v1 & WebSocket Engine (Port $BHTTP_PORT)
After=network.target ssh.service

[Service]
Type=simple
User=root
WorkingDirectory=$BHTTP_DIR
ExecStart=/usr/bin/python3 $BHTTP_DIR/bhttp_tunnel.py
Restart=always
RestartSec=2
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bhttp.service >/dev/null 2>&1
systemctl restart bhttp.service

IP_VPS=$(curl -s ipv4.icanhazip.com)
DOM=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "$IP_VPS" )

clear
echo -e "${C_GREEN}[✔] ¡Motor BHTTP v1 instalado y activo en el puerto $BHTTP_PORT!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 Host / IP       : ${C_YELLOW}$DOM${C_NC}"
echo -e " 🎯 Puerto BHTTP    : ${C_YELLOW}$BHTTP_PORT${C_NC}"
echo -e " ⚡ Modos Soportados: ${C_GREEN}BHTTP v1 (Directo) + Payload + WS${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_YELLOW}En UltraCustom puedes conectar de dos formas:${C_NC}"
echo -e " 1️⃣ Modo BHTTP v1 : Sin marcar casillas (${IP_VPS}:8080@usuario:clave)"
echo -e " 2️⃣ Modo Payload  : Marcando 'Payload' o 'Optimized'"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presione Enter para regresar al menú..."
