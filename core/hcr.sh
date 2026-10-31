#!/bin/bash
# ==========================================
# Instalador HCR Plain - Golbert VPS
# ==========================================
C_ORANGE='\033[38;5;214m'; C_BLUE='\033[1;34m'; C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_RED='\033[1;31m'; C_NC='\033[0m'
DEFAULT_PORT=8880

clear
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
echo -e "               ${C_BLUE}INSTALACIÓN DE HCR PLAIN${C_NC}"
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
echo -e "\n${C_ORANGE}Preparando entorno HCR...${C_NC}"

mkdir -p /etc/vps-manager/hcr
systemctl stop hcr > /dev/null 2>&1
sleep 1 
echo -e "${C_CYAN}[OK] Entorno preparado${C_NC}\n"

while true; do
    read -p "$(echo -e "${C_ORANGE}Puerto de escucha (--port) [Default $DEFAULT_PORT]: ${C_NC}")" INPUT_PORT
    FINAL_PORT=${INPUT_PORT:-$DEFAULT_PORT}

    if ! [[ "$FINAL_PORT" =~ ^[0-9]+$ ]]; then
        echo -e " ${C_RED}[!] Error: Debes ingresar un número válido.${C_NC}\n"
        continue
    fi
    if netstat -tuln | grep -qE ":$FINAL_PORT\b"; then
        echo -e " ${C_RED}[!] Error: El puerto $FINAL_PORT ya está en uso. Elige otro.${C_NC}\n"
    else
        break
    fi
done

echo -e "\n${C_GREEN}[OK] Configurando motor HCR en el puerto $FINAL_PORT...${C_NC}"

cat << 'EOF' > /etc/vps-manager/hcr/hcr_proxy.py
import socket, threading, sys

def handle_client(client_socket):
    try:
        ssh_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh_socket.connect(('127.0.0.1', 22))
        
        request = client_socket.recv(8192)
        if not request:
            client_socket.close()
            return
            
        if b"HTTP/" in request or b"CONNECT" in request:
            client_socket.sendall(b"HTTP/1.1 200 OK\r\n\r\n")
        else:
            ssh_socket.sendall(request)
            
        def transfer(src, dst):
            try:
                while True:
                    data = src.recv(8192)
                    if not data: break
                    dst.sendall(data)
            except: pass
            finally:
                src.close(); dst.close()

        threading.Thread(target=transfer, args=(client_socket, ssh_socket), daemon=True).start()
        threading.Thread(target=transfer, args=(ssh_socket, client_socket), daemon=True).start()
    except:
        client_socket.close()

if __name__ == '__main__':
    port = int(sys.argv[1])
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', port))
    server.listen(1000)
    while True:
        try:
            client, _ = server.accept()
            threading.Thread(target=handle_client, args=(client,), daemon=True).start()
        except: pass
EOF

cat << EOF > /etc/systemd/system/hcr.service
[Unit]
Description=HCR Plain Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/vps-manager/hcr
ExecStart=/usr/bin/python3 /etc/vps-manager/hcr/hcr_proxy.py $FINAL_PORT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hcr >/dev/null 2>&1
systemctl restart hcr

echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
echo -e " ${C_GREEN}✅ INSTALACIÓN COMPLETADA EXITOSAMENTE${C_NC}"
echo -e " ${C_CYAN}▶️ Protocolo HCR corriendo en el puerto : $FINAL_PORT${C_NC}"
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
read -p " Presiona Enter para volver al menú..."
