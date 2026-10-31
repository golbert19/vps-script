#!/bin/bash
# ==========================================
# Instalador HCR Plain - URL Corregida
# ==========================================
C_ORANGE='\033[38;5;214m'; C_BLUE='\033[1;34m'; C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_RED='\033[1;31m'; C_NC='\033[0m'
DEFAULT_PORT=8880

clear
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
echo -e "               ${C_BLUE}INSTALACIÓN DE HCR PLAIN${C_NC}"
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
mkdir -p /etc/vps-manager/hcr
systemctl stop hcr > /dev/null 2>&1

# URL corregida apuntando a la carpeta core/
wget -qO /etc/vps-manager/hcr/hcr-server "https://raw.githubusercontent.com/golbert19/vps-script/main/core/hcr-server"
chmod +x /etc/vps-manager/hcr/hcr-server

if grep -q "404: Not Found" /etc/vps-manager/hcr/hcr-server || [ ! -s /etc/vps-manager/hcr/hcr-server ]; then
    echo -e "\n${C_RED}[!] ERROR CRÍTICO: El archivo 'hcr-server' no fue encontrado en GitHub.${C_NC}"
    read -p " Presiona Enter para cancelar la instalación..."
    exit 1
fi

while true; do
    read -p "$(echo -e "${C_ORANGE}Puerto de escucha [Default $DEFAULT_PORT]: ${C_NC}")" INPUT_PORT
    FINAL_PORT=${INPUT_PORT:-$DEFAULT_PORT}
    if ! [[ "$FINAL_PORT" =~ ^[0-9]+$ ]]; then echo -e " ${C_RED}[!] Número inválido.${C_NC}"; continue; fi
    if netstat -tuln | grep -qE ":$FINAL_PORT\b"; then echo -e " ${C_RED}[!] Puerto en uso.${C_NC}"; else break; fi
done

cat << EOF > /etc/systemd/system/hcr.service
[Unit]
Description=HCR Plain Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/vps-manager/hcr
ExecStart=/etc/vps-manager/hcr/hcr-server $FINAL_PORT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hcr >/dev/null 2>&1
systemctl restart hcr
sleep 2

if systemctl is-active --quiet hcr; then
    echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
    echo -e " ${C_GREEN}✅ HCR operando en el puerto $FINAL_PORT con éxito${C_NC}"
    echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
else
    echo -e "\n${C_RED}[!] Error: El servicio HCR colapsó.${C_NC}"
    journalctl -u hcr -n 10 --no-pager
fi
read -p " Presiona Enter para volver..."
