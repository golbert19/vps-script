#!/bin/bash
# ==========================================
# Módulo: Actualizador Completo (Golbert VPS)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🔄 ${C_YELLOW}ACTUALIZADOR COMPLETO - GOLBERT VPS${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_YELLOW}[+] Conectando con GitHub para descargar toda la actualización...${C_NC}"

REPO_URL="https://raw.githubusercontent.com/golbert19/vps-script/main"

# 1. Actualizar menú principal y archivos base
echo -e "\n${C_CYAN}[1/3] Actualizando Menú Principal y Base...${C_NC}"
wget --progress=bar:force "$REPO_URL/menu.sh" -O /usr/local/bin/menu
wget --progress=bar:force "$REPO_URL/languages.sh" -O /etc/vps-manager/languages.sh 2>/dev/null
wget --progress=bar:force "$REPO_URL/install.sh" -O /etc/vps-manager/install.sh 2>/dev/null

chmod +x /usr/local/bin/menu /etc/vps-manager/languages.sh /etc/vps-manager/install.sh 2>/dev/null

# 2. Lista completa de todos los submódulos de la carpeta core (Actualizado)
CORE_FILES=(
    "specs.sh" "fix_ports.sh" "domain.sh" "banner.sh" "update.sh" 
    "user.sh" "bot.sh" "webpanel.sh" "firewall.sh" "checkuser.sh"
    "xray_manager.sh" "vmess.sh" "vless.sh" "trojan.sh" "slowdns.sh"
    "badvpn.sh" "hcr.sh" "hysteria.sh" "udp_custom.sh" "bhttp.sh"
    "sshws.sh" "ssl.sh" "setup_openvpn.sh" "zivpn.sh" "bbr.sh"
    "php.sh" "ports.sh"
)

echo -e "\n${C_CYAN}[2/3] Sincronizando todos los submódulos de la carpeta core...${C_NC}"
mkdir -p /etc/vps-manager/core

for file in "${CORE_FILES[@]}"; do
    echo -e "  -> Actualizando: $file"
    wget -qO /etc/vps-manager/core/$file "$REPO_URL/core/$file" 2>/dev/null
    chmod +x /etc/vps-manager/core/$file 2>/dev/null
done

# 3. Verificación final de permisos globales
echo -e "\n${C_CYAN}[3/3] Aplicando permisos de ejecución y optimizando...${C_NC}"
chmod +x /etc/vps-manager/core/*.sh 2>/dev/null

echo -e "\n${C_GREEN}[✔] ¡Actualización completa finalizada con éxito!${C_NC}"
echo -e "${C_YELLOW}Todos los instaladores y módulos están al día.${C_NC}"
echo -e "${C_YELLOW}Reiniciando el panel en 2 segundos...${C_NC}"
sleep 2
clear
menu
