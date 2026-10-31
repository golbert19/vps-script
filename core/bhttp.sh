#!/bin/bash
# ==========================================
# Instalador BHTTP Proxy - Seguro y Funcional
# ==========================================
C_ORANGE='\033[38;5;214m'; C_BLUE='\033[1;34m'; C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_RED='\033[1;31m'; C_NC='\033[0m'
DEFAULT_PORT=8180

clear
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
echo -e "               ${C_BLUE}INSTALACIÓN DE BHTTP${C_NC}"
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
mkdir -p /etc/vps-manager/bhttp
systemctl stop bhttp > /dev/null 2>&1

apt-get install -y python3-pam > /dev/null 2>&1

# Descargar desde la ruta correcta (asumiendo que BHTTP.py está en la raíz, si está en core/ cambia la URL)
wget -qO /etc/vps-manager/bhttp/BHTTP.py "https://raw.githubusercontent.com/golbert19/vps-script/main/BHTTP.py"

while true; do
    read -p "$(echo -e "${C_ORANGE}Puerto de escucha [Default $DEFAULT_PORT]: ${C_NC}")" INPUT_PORT
    FINAL_PORT=${INPUT_PORT:-$DEFAULT_PORT}
    if ! [[ "$FINAL_PORT" =~ ^[0-9]+$ ]]; then echo -e " ${C_RED}[!] Número inválido.${C_NC}"; continue; fi
    if netstat -tuln | grep -qE ":$FINAL_PORT\b"; then echo -e " ${C_RED}[!] Puerto en uso.${C_NC}"; else break; fi
done

echo -e "\n${C_GREEN}[OK] Configurando puerto $FINAL_PORT...${C_NC}"

# 1. Cambiamos el puerto
sed -i "s/\"port\": 80/\"port\": $FINAL_PORT/g" /etc/vps-manager/bhttp/BHTTP.py
# 2. Desactivamos SSL (que causa el crash porque los certificados no existen)
sed -i 's/"ssl": True/"ssl": False/g' /etc/vps-manager/bhttp/BHTTP.py

cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=BHTTP Proxy Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/vps-manager/bhttp
ExecStart=/usr/bin/python3 /etc/vps-manager/bhttp/BHTTP.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bhttp >/dev/null 2>&1
systemctl restart bhttp
sleep 2

if systemctl is-active --quiet bhttp; then
    echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
    echo -e " ${C_GREEN}✅ BHTTP operando en el puerto $FINAL_PORT con éxito${C_NC}"
    echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
else
    echo -e "\n${C_RED}[!] Error crítico: El servicio BHTTP colapsó al iniciar.${C_NC}"
    journalctl -u bhttp -n 10 --no-pager
fi
read -p " Presiona Enter para volver..."
