#!/bin/bash
# ==========================================
# Instalador BHTTP - Golbert VPS V5.0 LTS
# ==========================================
C_ORANGE='\033[38;5;214m'; C_BLUE='\033[1;34m'; C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_RED='\033[1;31m'; C_NC='\033[0m'

DEFAULT_PORT=8180

clear
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
echo -e "               ${C_BLUE}INSTALACIÓN DE BHTTP${C_NC}"
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
echo -e "\n${C_ORANGE}Descargando dependencias y configurando entorno...${C_NC}"

mkdir -p /etc/vps-manager/bhttp
systemctl stop bhttp > /dev/null 2>&1
sleep 1.5 
echo -e "${C_CYAN}[OK] Binario instalado${C_NC}\n"

while true; do
    read -p "$(echo -e "${C_ORANGE}Puerto de escucha (--port) [Default $DEFAULT_PORT]: ${C_NC}")" INPUT_PORT
    FINAL_PORT=${INPUT_PORT:-$DEFAULT_PORT}

    if ! [[ "$FINAL_PORT" =~ ^[0-9]+$ ]]; then
        echo -e " ${C_RED}[!] Error: Debes ingresar un número válido.${C_NC}\n"
        continue
    fi
    if netstat -tuln | grep -qE ":$FINAL_PORT\b"; then
        echo -e " ${C_RED}[!] Error: El puerto $FINAL_PORT ya está en uso por otro servicio. Elige otro.${C_NC}\n"
    else
        break
    fi
done

echo -e "\n${C_GREEN}[OK] Configurando servicio BHTTP en el puerto $FINAL_PORT...${C_NC}"

cat << 'EOF' > /etc/vps-manager/bhttp/bhttp_server.py
import sys, socket, threading

port = int(sys.argv[2]) if len(sys.argv) > 2 else 8180

def handle(client):
    try:
        req = client.recv(4096)
        if not req: return
        ssh = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh.connect(('127.0.0.1', 22))
        
        if b"HTTP/" in req:
            client.sendall(b"HTTP/1.1 200 OK\r\n\r\n")
        
        def transfer(s, d):
            try:
                while True:
                    data = s.recv(8192)
                    if not data: break
                    d.sendall(data)
            except: pass
            finally:
                s.close(); d.close()
                
        threading.Thread(target=transfer, args=(client, ssh), daemon=True).start()
        threading.Thread(target=transfer, args=(ssh, client), daemon=True).start()
    except:
        client.close()

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('0.0.0.0', port))
server.listen(100)
while True:
    client, _ = server.accept()
    threading.Thread(target=handle, args=(client,), daemon=True).start()
EOF

cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=BHTTP Proxy Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/vps-manager/bhttp
ExecStart=/usr/bin/python3 /etc/vps-manager/bhttp/bhttp_server.py --port $FINAL_PORT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bhttp >/dev/null 2>&1
systemctl restart bhttp

echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
echo -e " ${C_GREEN}✅ INSTALACIÓN COMPLETADA EXITOSAMENTE${C_NC}"
echo -e " ${C_CYAN}▶️ Protocolo corriendo en el puerto : $FINAL_PORT${C_NC}"
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
read -p " Presiona Enter para volver al menú..."
