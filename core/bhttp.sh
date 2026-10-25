#!/bin/bash
# ==========================================
# Módulo: Proxy Python Multi-Inyección (BHTTP 8080)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}[+] Instalando y configurando Proxy Python Multi-Inyección (Puerto 8080)...${C_NC}"

apt update -y && apt install -y python3 iptables >/dev/null 2>&1

BHTTP_DIR="/etc/vps-manager/bhttp"
mkdir -p "$BHTTP_DIR"

# Script Python ultra-avanzado (Soporta Payload HTTP y SSH Directo simultáneamente)
cat << 'EOF' > "$BHTTP_DIR/bhttp_server.py"
import socket
import threading

LISTENING_PORT = 8080
SSH_PORT = 22

def handle_client(client_socket):
    try:
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.connect(('127.0.0.1', SSH_PORT))
        
        # Leer petición inicial
        initial_data = client_socket.recv(8192)
        if initial_data:
            # Si el cliente manda un Payload HTTP (GET, POST, CONNECT...)
            if initial_data.startswith(b"CONNECT") or initial_data.startswith(b"GET") or initial_data.startswith(b"POST") or initial_data.startswith(b"PUT") or b"HTTP/" in initial_data:
                # Responder 200 OK para engañar a la operadora
                client_socket.sendall(b"HTTP/1.1 200 Connection Established\r\n\r\n")
            else:
                # Si es SSH directo sin payload, enviar los datos directamente al puerto 22
                server_socket.sendall(initial_data)

        def forward(src, dst):
            while True:
                try:
                    data = src.recv(8192)
                    if not data:
                        break
                    dst.sendall(data)
                except:
                    break

        t1 = threading.Thread(target=forward, args=(client_socket, server_socket))
        t2 = threading.Thread(target=forward, args=(server_socket, client_socket))
        t1.start()
        t2.start()
        t1.join()
        t2.join()
    except:
        pass
    finally:
        client_socket.close()
        server_socket.close()

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', LISTENING_PORT))
    server.listen(500)
    print(f"Proxy Inteligente escuchando en puerto {LISTENING_PORT} -> SSH {SSH_PORT}")
    while True:
        client, addr = server.accept()
        threading.Thread(target=handle_client, args=(client,)).start()

if __name__ == '__main__':
    main()
EOF

chmod +x "$BHTTP_DIR/bhttp_server.py"

# Abrir el puerto 8080 en Iptables
iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null

# Crear servicio Systemd
cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=Python Proxy Multi-Injector 8080
After=network.target

[Service]
ExecStart=/usr/bin/python3 $BHTTP_DIR/bhttp_server.py
Restart=always
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bhttp >/dev/null 2>&1
systemctl restart bhttp

IP_VPS=$(curl -s ipv4.icanhazip.com)
clear
echo -e "${C_GREEN}[✔] ¡Proxy BHTTP instalado y activo con éxito!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 Host / IP : $IP_VPS"
echo -e " 🎯 Puerto    : 8080 (Multi-Payload)"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presione Enter para regresar..."
