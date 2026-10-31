#!/bin/bash
C_ORANGE='\033[38;5;214m'; C_BLUE='\033[1;34m'; C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_RED='\033[1;31m'; C_NC='\033[0m'
DEFAULT_PORT=8180

clear
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
echo -e "               ${C_BLUE}INSTALACIÓN DE BHTTP${C_NC}"
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
mkdir -p /etc/vps-manager/bhttp
systemctl stop bhttp > /dev/null 2>&1

# Descargar TU script original modificado
wget -qO /etc/vps-manager/bhttp/BHTTP.py "https://raw.githubusercontent.com/golbert19/vps-script/main/BHTTP.py"

while true; do
    read -p "$(echo -e "${C_ORANGE}Puerto de escucha (--port) [Default $DEFAULT_PORT]: ${C_NC}")" INPUT_PORT
    FINAL_PORT=${INPUT_PORT:-$DEFAULT_PORT}
    if ! [[ "$FINAL_PORT" =~ ^[0-9]+$ ]]; then echo -e " ${C_RED}[!] Número inválido.${C_NC}"; continue; fi
    if netstat -tuln | grep -qE ":$FINAL_PORT\b"; then echo -e " ${C_RED}[!] Puerto en uso.${C_NC}"; else break; fi
done

cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=BHTTP Proxy Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/vps-manager/bhttp
# Aquí inyectamos el puerto dinámico a tu script Python
ExecStart=/usr/bin/python3 /etc/vps-manager/bhttp/BHTTP.py $FINAL_PORT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bhttp >/dev/null 2>&1
systemctl restart bhttp
echo -e "\n ${C_GREEN}✅ BHTTP instalado y corriendo en el puerto $FINAL_PORT${C_NC}\n"
read -p " Presiona Enter..."
