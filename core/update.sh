#!/bin/bash
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🔄 ${C_YELLOW}ACTUALIZADOR DE PANEL - GOLBERT VPS${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_YELLOW}[+] Conectando con GitHub para descargar actualizaciones...${C_NC}"

# Creamos un directorio temporal para la descarga limpia
mkdir -p /etc/vps-manager/temp_update
cd /etc/vps-manager/temp_update

# Descargar el menú principal con barra de progreso visible
echo -e "${C_CYAN}[1/2] Actualizando Menú Principal...${C_NC}"
wget --progress=bar:force https://raw.githubusercontent.com/golbert19/vps-script/main/menu.sh -O /usr/local/bin/menu
chmod +x /usr/local/bin/menu

# Descargar el actualizador maestro si existe
echo -e "${C_CYAN}[2/2] Sincronizando scripts del sistema...${C_NC}"
wget --progress=bar:force https://raw.githubusercontent.com/golbert19/vps-script/main/install.sh -O /etc/vps-manager/install.sh 2>/dev/null

echo -e "\n${C_GREEN}[✔] ¡Actualización completada con éxito!${C_NC}"
echo -e "${C_YELLOW}El panel se reiniciará para aplicar los cambios.${C_NC}"
sleep 2
clear
menu
