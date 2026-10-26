#!/bin/bash
# ==========================================
# Módulo: BHTTP Pro Proxy (Python Core - Puerto 8080)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

BHTTP_DIR="/etc/vps-manager/bhttp"
BHTTP_PORT=8080
SSH_PORT=22

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}    INSTALADOR BHTTP PRO (PUERTO 8080)          ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

apt update -y >/dev/null 2>&1
apt install -y python3 iptables net-tools psmisc ufw >/dev/null 2>&1

systemctl stop bhttp.service >/dev/null 2>&1
fuser -k ${BHTTP_PORT}/tcp >/dev/null 2>&1

mkdir -p "$BHTTP_DIR"

cat << 'EOF' > "$BHTTP_DIR/bhttp_server.py"
import socket
import threading
import select
import sys

LISTEN_HOST = '0.0.0.0'
LISTEN_PORT = 8080
TARGET_HOST = '127.0.0.1'
TARGET_PORT = 22
BUFFER_SIZE = 65535

def handle_client(client_sock):
    target_sock = None
    try:
        client_sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        client_sock.settimeout(10)
        
        request = client_sock.recv(BUFFER_SIZE)
        if not request:
            client_sock.close()
            return

        target_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        target_sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        target_sock.connect((TARGET_HOST, TARGET_PORT))

        if request.startswith(b'SSH-'):
            target_sock.sendall(request)
        else:
            response = (
                b"HTTP/1.1 200 OK\r\n"
                b"Connection: keep-alive\r\n"
                b"Proxy-Connection: keep-alive\r\n"
                b"Content-Length: 0\r\n\r\n"
            )
            try:
                client_sock.sendall(response)
            except:
                pass

            if b'SSH-' in request:
                idx = request.find(b'SSH-')
                target_sock.sendall(request[idx:])

        client_sock.settimeout(None)
        
        sockets = [client_sock, target_sock]
        while True:
            r, _, e = select.select(sockets, [], sockets, 60)
            if e or not r:
                break
            for s in r:
                data = s.recv(BUFFER_SIZE)
                if not data:
                    return
                if s is client_sock:
                    target_sock.sendall(data)
                else:
                    client_sock.sendall(data)
    except:
        pass
    finally:
        try: client_sock.close()
        except: pass
        try: target_sock.close()
        except: pass

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server.bind((LISTEN_HOST, LISTEN_PORT))
        server.listen(1024)
    except Exception as e:
        sys.exit(1)

    while True:
        try:
            client_sock, _ = server.accept()
            t = threading.Thread(target=handle_client, args=(client_sock,), daemon=True)
            t.start()
        except:
            continue

if __name__ == '__main__':
    main()
EOF

chmod +x "$BHTTP_DIR/bhttp_server.py"

iptables -D INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT 2>/dev/null
iptables -I INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
ufw allow ${BHTTP_PORT}/tcp >/dev/null 2>&1

cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=BHTTP Pro Proxy Service (Port $BHTTP_PORT)
After=network.target ssh.service

[Service]
Type=simple
User=root
WorkingDirectory=$BHTTP_DIR
ExecStart=/usr/bin/python3 $BHTTP_DIR/bhttp_server.py
Restart=always
RestartSec=2
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bhttp.service >/dev/null 2>&1
systemctl restart bhttp.service

clear
echo -e "${C_GREEN}[✔] ¡BHTTP Pro instalado y activo en el puerto $BHTTP_PORT!${C_NC}"
read -p "Presione Enter para regresar..."
