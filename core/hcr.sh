#!/bin/bash
# ==========================================
# Instalador HCR Plain - Corrección de Escucha (Listen)
# ==========================================
C_ORANGE='\033[38;5;214m'; C_BLUE='\033[1;34m'; C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_RED='\033[1;31m'; C_NC='\033[0m'
DEFAULT_PORT=8880

clear
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
echo -e "               ${C_BLUE}INSTALACIÓN DE HCR PLAIN${C_NC}"
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
mkdir -p /etc/vps-manager/hcr
systemctl stop hcr > /dev/null 2>&1

# Descargar el binario
wget -qO /etc/vps-manager/hcr/hcr-server "https://raw.githubusercontent.com/golbert19/vps-script/main/core/hcr-server"
chmod +x /etc/vps-manager/hcr/hcr-server

# Generar certificados para evitar que el binario colapse por falta de SSL
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/vps-manager/hcr/server.key -out /etc/vps-manager/hcr/server.crt -subj "/CN=hcr-server" > /dev/null 2>&1

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
# Opción 1 (Más probable): Escuchar en todas las interfaces (0.0.0.0) en el puerto definido
ExecStart=/etc/vps-manager/hcr/hcr-server --listen 0.0.0.0:$FINAL_PORT --tls-cert /etc/vps-manager/hcr/server.crt --tls-key /etc/vps-manager/hcr/server.key

# Si la Opción 1 falla, comenta la línea de arriba y descomenta una de las siguientes:
# Opción 2: Usar bandera -p
# ExecStart=/etc/vps-manager/hcr/hcr-server -p $FINAL_PORT --tls-cert /etc/vps-manager/hcr/server.crt --tls-key /etc/vps-manager/hcr/server.key
# Opción 3: Puerto directo
# ExecStart=/etc/vps-manager/hcr/hcr-server $FINAL_PORT --tls-cert /etc/vps-manager/hcr/server.crt --tls-key /etc/vps-manager/hcr/server.key

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
