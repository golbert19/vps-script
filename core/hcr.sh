#!/bin/bash
# ==========================================
# Instalador HCR Nativo - Golbert VPS V5.0 LTS
# ==========================================
C_ORANGE='\033[38;5;214m'; C_BLUE='\033[1;34m'; C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_RED='\033[1;31m'; C_NC='\033[0m'

DEFAULT_PORT=8880

clear
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
echo -e "               ${C_BLUE}INSTALACIÓN DE HCR NATIVO${C_NC}"
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
echo -e "\n${C_ORANGE}Descargando binario de HCR...${C_NC}"

mkdir -p /etc/vps-manager/hcr
systemctl stop hcr > /dev/null 2>&1

# (Si tienes un link directo para tu binario HCR, agrégalo aquí abajo)
# wget -qO /etc/vps-manager/hcr/hcr-server "TU_LINK_DE_GITHUB"
# chmod +x /etc/vps-manager/hcr/hcr-server

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
        echo -e " ${C_RED}[!] Error: El puerto $FINAL_PORT ya está en uso. Elige otro.${C_NC}\n"
    else
        break
    fi
done

echo -e "\n${C_GREEN}[OK] Configurando HCR en el puerto $FINAL_PORT...${C_NC}"

cat << EOF > /etc/systemd/system/hcr.service
[Unit]
Description=HCR Nativo Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/vps-manager/hcr
# Aquí se ejecuta el binario con el puerto seleccionado
ExecStart=/usr/bin/python3 -m http.server $FINAL_PORT
# Nota: Si usas un binario precompilado, cambia la línea de arriba a:
# ExecStart=/etc/vps-manager/hcr/hcr-server --port $FINAL_PORT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hcr >/dev/null 2>&1
systemctl restart hcr

echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
echo -e " ${C_GREEN}✅ INSTALACIÓN COMPLETADA EXITOSAMENTE${C_NC}"
echo -e " ${C_CYAN}▶️ Protocolo corriendo en el puerto : $FINAL_PORT${C_NC}"
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
read -p " Presiona Enter para volver al menú..."
