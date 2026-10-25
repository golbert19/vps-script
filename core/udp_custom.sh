#!/bin/bash
# ==========================================
# Módulo: UDP Custom (Oficial HTTP Custom)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}       GESTOR UDP CUSTOM (JUEGOS Y LLAMADAS)    ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_YELLOW}[+] Lanzando el instalador oficial de UDP Custom...${C_NC}"
echo -e "Por favor, sigue las instrucciones en pantalla.\n"
sleep 2

# Ejecuta exactamente el comando que solicitaste
bash <(curl -sSL 'https://raw.githubusercontent.com/http-custom/udp-custom/main/module/module')

echo -e "\n${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}[✔] Operación de UDP Custom finalizada.${C_NC}"
read -p "Presione Enter para regresar al Menú Principal..."
