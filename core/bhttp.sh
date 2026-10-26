#!/bin/bash
# ==========================================
# Módulo: BHTTP v1 Proxy (Dual-Stream + Puerto Dinámico)
# Compatible con UltraCustom / HTTP Custom
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

BHTTP_DIR="/etc/vps-manager/bhttp"
SSH_PORT=22

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   INSTALADOR BHTTP v1 PRO (PUERTO DINÁMICO)    ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

read -p "Ingresa el puerto para BHTTP [Por defecto 8080]: " INPUT_PORT
BHTTP_PORT=${INPUT_PORT:-8080}

mkdir -p /etc/vps-manager
echo "$BHTTP_PORT" > /etc/vps-manager/bhttp_port

apt update -y >/dev/null 2>&1
apt install -y python3 iptables net-tools psmisc ufw >/dev/null 2>&1

systemctl stop bhttp.service >/dev/null 2>&1
fuser -k ${BHTTP_PORT}/tcp >/dev/null 2>&1

mkdir -p "$BHTTP_DIR"

cat << EOF > "$BHTTP_DIR/bhttp_tunnel.py"
#!/usr/bin/env python3
import socket, threading, select, time, sys

LISTEN_HOST = '0.0.0.0'
LISTEN_PORT = $BHTTP_PORT
SSH_HOST = '127.0.0.1'
SSH_PORT = $SSH_PORT
BUFFER_SIZE = 65535

SESSIONS = {}
SESSIONS_LOCK = threading.Lock()

def connect_ssh():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    s.connect((SSH_HOST, SSH_PORT))
    return s

def bridge(sock1, sock2):
    sockets = [sock1, sock2]
    try:
        while True:
            r, _, e = select.select(sockets, [], sockets, 60)
            if e or not r: break
            for s in r:
                data = s.recv(BUFFER_SIZE)
                if not data: return
                if s is sock1: sock2.sendall(data)
                else: sock1.sendall(data)
    except: pass
    finally:
        for s in sockets:
            try: s.close()
            except: pass

def get_session_key(ip, path, headers):
    for k in ('x-session-id', 'x-id', 'x-bhttp-id', 'id', 'session'):
        if k in headers: return f"{ip}_{headers[k]}"
    return f"{ip}_{path}" if path and path != "/" else f"{ip}_default"

def cleanup():
    while True:
        time.sleep(30)
        now = time.time()
        with SESSIONS_LOCK:
            expired = [k for k, v in SESSIONS.items() if now - v['ts'] > 120]
            for k in expired:
                try: SESSIONS[k]['ssh'].close()
                except: pass
                del SESSIONS[k]

def handle_client(client_sock, addr):
    client_ip = addr[0]
    try:
        client_sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        client_sock.settimeout(15)
        data = b""
        
        while b"\r\n\r\n" not in data:
            chunk = client_sock.recv(BUFFER_SIZE)
            if not chunk: return
            data += chunk
            if data.startswith(b"SSH-") or len(data) > 8192: break

        client_sock.settimeout(None)

        if data.startswith(b"SSH-"):
            ssh_sock = connect_ssh()
            ssh_sock.sendall(data)
            bridge(client_sock, ssh_sock)
            return

        if b"\r\n\r\n" not in data: return

        header_bytes, body = data.split(b"\r\n\r\n", 1)
        lines = header_bytes.decode('latin-1', errors='ignore').split("\r\n")
        first_line = lines[0].split(" ")
        method = first_line[0].upper() if len(first_line) > 0 else "GET"
        path = first_line[1] if len(first_line) > 1 else "/"

        headers = {line.split(":", 1)[0].strip().lower(): line.split(":", 1)[1].strip() for line in lines[1:] if ":" in line}
        is_websocket = "upgrade" in headers.get("connection", "").lower()

        sess_key = get_session_key(client_ip, path, headers)

        if method in ("POST", "PUT") and not is_websocket:
            with SESSIONS_LOCK:
                if sess_key not in SESSIONS:
                    SESSIONS[sess_key] = {'ssh': connect_ssh(), 'ts': time.time()}
                ssh_sock = SESSIONS[sess_key]['ssh']
                SESSIONS[sess_key]['ts'] = time.time()
            
            client_sock.sendall(b"HTTP/1.1 200 OK\r\nConnection: keep-alive\r\nCache-Control: no-cache\r\n\r\n")
            if body: ssh_sock.sendall(body)
            
            # Simple un-chunking loop
            is_chunked = "chunked" in headers.get("transfer-encoding", "").lower()
            if not is_chunked:
                bridge(client_sock, ssh_sock)
            else:
                buf = b""
                while True:
                    while b"\r\n" not in buf:
                        c = client_sock.recv(BUFFER_SIZE)
                        if not c: return
                        buf += c
                    line, buf = buf.split(b"\r\n", 1)
                    try: length = int(line.split(b";")[0].strip(), 16)
                    except: 
                        ssh_sock.sendall(line + b"\r\n" + buf)
                        bridge(client_sock, ssh_sock)
                        return
                    if length == 0: break
                    while len(buf) < length + 2:
                        c = client_sock.recv(BUFFER_SIZE)
                        if not c: return
                        buf += c
                    ssh_sock.sendall(buf[:length])
                    buf = buf[length+2:]
            return

        with SESSIONS_LOCK:
            if sess_key in SESSIONS:
                ssh_sock = SESSIONS[sess_key]['ssh']
                SESSIONS[sess_key]['ts'] = time.time()
            else:
                ssh_sock = connect_ssh()
                SESSIONS[sess_key] = {'ssh': ssh_sock, 'ts': time.time()}

        if is_websocket:
            client_sock.sendall(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
        else:
            client_sock.sendall(b"HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nConnection: keep-alive\r\nCache-Control: no-cache\r\n\r\n")

        if body:
            if b"SSH-" in body: ssh_sock.sendall(body[body.find(b"SSH-"):])
            else: ssh_sock.sendall(body)

        bridge(client_sock, ssh_sock)

    except: pass
    finally:
        try: client_sock.close()
        except: pass

def main():
    threading.Thread(target=cleanup, daemon=True).start()
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((LISTEN_HOST, LISTEN_PORT))
    server.listen(1024)
    while True:
        try:
            client_sock, addr = server.accept()
            threading.Thread(target=handle_client, args=(client_sock, addr), daemon=True).start()
        except: continue

if __name__ == '__main__': main()
EOF

chmod +x "$BHTTP_DIR/bhttp_tunnel.py"

iptables -D INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT 2>/dev/null
iptables -I INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
ufw allow ${BHTTP_PORT}/tcp >/dev/null 2>&1

cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=Golbert BHTTP v1 Proxy (Port $BHTTP_PORT)
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
echo -e "${C_GREEN}[✔] ¡Motor BHTTP v1 activo en el puerto $BHTTP_PORT!${C_NC}"
read -p "Presione Enter para regresar..."
