#!/bin/bash
# ==========================================
# Módulo: BHTTP & BTUN Bidirectional Tunnel (Puerto 8080)
# Compatible con Ubuntu 22.04 / 24.04 / 26.04 LTS
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

BHTTP_DIR="/etc/vps-manager/bhttp"
BHTTP_PORT=8080
SSH_PORT=22

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   INSTALADOR BHTTP / BTUN TUNNEL (PUERTO 8080) ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}[+] Preparando dependencias y liberando el puerto $BHTTP_PORT...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y python3 iptables net-tools psmisc ufw >/dev/null 2>&1

# Detener servicios previos que ocupen el puerto 8080
systemctl stop bhttp.service >/dev/null 2>&1
fuser -k ${BHTTP_PORT}/tcp >/dev/null 2>&1

mkdir -p "$BHTTP_DIR"

echo -e "${C_YELLOW}[+] Creando motor bidireccional BHTTP/WebSocket en puerto $BHTTP_PORT...${C_NC}"

cat << 'EOF' > "$BHTTP_DIR/bhttp_tunnel.py"
#!/usr/bin/env python3
import socket
import threading
import select
import sys

LISTEN_HOST = '0.0.0.0'
LISTEN_PORT = 8080
TARGET_HOST = '127.0.0.1'
TARGET_PORT = 22
BUFFER_SIZE = 65535

def bidirectional_tunnel(client_sock, target_sock):
    """Túnel bidireccional de baja latencia estilo btun"""
    sockets = [client_sock, target_sock]
    try:
        while True:
            readable, _, exceptional = select.select(sockets, [], sockets, 60)
            if exceptional or not readable:
                break
            for sock in readable:
                data = sock.recv(BUFFER_SIZE)
                if not data:
                    return
                if sock is client_sock:
                    target_sock.sendall(data)
                else:
                    client_sock.sendall(data)
    except Exception:
        pass
    finally:
        try:
            client_sock.close()
        except Exception:
            pass
        try:
            target_sock.close()
        except Exception:
            pass

def handle_client(client_sock):
    target_sock = None
    try:
        client_sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        client_sock.settimeout(10)

        # Leer el primer paquete (Payload HTTP / WebSocket o directo SSH)
        payload = client_sock.recv(BUFFER_SIZE)
        if not payload:
            client_sock.close()
            return

        # Conectar internamente al servidor SSH local (Puerto 22)
        target_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        target_sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        target_sock.connect((TARGET_HOST, TARGET_PORT))

        # Si el cliente envía directamente el handshake SSH sin Payload HTTP
        if payload.startswith(b'SSH-'):
            target_sock.sendall(payload)
        else:
            # Respuesta compatible con BHTTP, WebSocket (btun) y HTTP Custom/Injector
            response = (
                b"HTTP/1.1 101 Switching Protocols\r\n"
                b"Upgrade: websocket\r\n"
                b"Connection: Upgrade\r\n"
                b"Server: Golbert-BHTTP-Tunnel\r\n\r\n"
            )
            client_sock.sendall(response)

            # Si el payload traía el handshake SSH pegado después del encabezado HTTP (Split/BHTTP)
            if b"SSH-" in payload:
                ssh_index = payload.find(b"SSH-")
                target_sock.sendall(payload[ssh_index:])

        client_sock.settimeout(None)
        bidirectional_tunnel(client_sock, target_sock)

    except Exception:
        if client_sock:
            try:
                client_sock.close()
            except Exception:
                pass
        if target_sock:
            try:
                target_sock.close()
            except Exception:
                pass

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server.bind((LISTEN_HOST, LISTEN_PORT))
        server.listen(512)
        print(f"[*] Túnel Bidireccional BHTTP activo en {LISTEN_HOST}:{LISTEN_PORT} -> {TARGET_HOST}:{TARGET_PORT}")
    except Exception as e:
        print(f"[!] Error al iniciar en el puerto {LISTEN_PORT}: {e}")
        sys.exit(1)

    while True:
        try:
            client_sock, _ = server.accept()
            t = threading.Thread(target=handle_client, args=(client_sock,))
            t.daemon = True
            t.start()
        except KeyboardInterrupt:
            break
        except Exception:
            continue

if __name__ == '__main__':
    main()
EOF

chmod +x "$BHTTP_DIR/bhttp_tunnel.py"

# Abrir el puerto 8080 en el Firewall
iptables -D INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT 2>/dev/null
iptables -I INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
ufw allow ${BHTTP_PORT}/tcp >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Configurando servicio Systemd permanente...${C_NC}"
cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=Golbert BHTTP Bidirectional Tunnel (Port $BHTTP_PORT)
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
echo -e "${C_GREEN}[✔] ¡Túnel Bidireccional BHTTP activo en el puerto $BHTTP_PORT!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 Host / Dominio : ${C_YELLOW}$DOM${C_NC}"
echo -e " 🎯 Puerto BHTTP   : ${C_YELLOW}$BHTTP_PORT${C_NC}"
echo -e " 🔄 Redirección    : ${C_YELLOW}0.0.0.0:$BHTTP_PORT <==> 127.0.0.1:$SSH_PORT (SSH)${C_NC}"
echo -e " ⚡ Estado         : ${C_GREEN}101 Switching Protocols (Bidireccional)${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_YELLOW}Ejemplo de Payload para BHTTP / HTTP Custom / Injector:${C_NC}"
echo -e "GET / HTTP/1.1[crlf]Host: $DOM[crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf][crlf]"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presione Enter para regresar al menú..."
