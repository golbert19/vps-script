#!/bin/bash
C_GREEN='\033[1;32m'
C_CYAN='\033[1;36m'
C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🔄 INICIANDO ACTUALIZACIÓN DEL PANEL..."
echo -e "${C_CYAN}================================================${C_NC}"

# INSTALAR DEPENDENCIAS DE LIMPIEZA PRIMERO
apt-get update -y > /dev/null 2>&1
apt-get install -y dos2unix > /dev/null 2>&1

REPO_URL="https://raw.githubusercontent.com/golbert19/vps-script/main"
mkdir -p /etc/vps-manager/core

echo "Descargando Menú y dependencias base..."
wget -qO /usr/local/bin/menu "$REPO_URL/menu.sh"
wget -qO /etc/vps-manager/languages.sh "$REPO_URL/languages.sh"
wget -qO /etc/vps-manager/version "$REPO_URL/version"

echo "Sincronizando carpeta Core..."
CORE_FILES=(
    "BHTTP.py" "bbr.sh" "slowdns.sh" "edit_ovpn_user.sh" "badvpn.sh" 
    "banner.sh" "bhttp.sh" "bot.sh" "checkuser.sh" "domain.sh" 
    "firewall.sh" "fix_ports.sh" "hcr-server" "hcr.sh" "hysteria.sh" 
    "limiter.sh" "master.py" "php.sh" "ports.sh" "proxy.py" 
    "setup_dns.sh" "setup_hysteria.sh" "setup_openvpn.sh" "setup_zivpn.sh" 
    "specs.sh" "ssh.sh" "sshws.sh" "ssl.sh" "trojan.sh" 
    "udp_custom.sh" "update.sh" "user.sh" "vless.sh" "vmess.sh" 
    "webpanel.sh" "websocket.sh" "xray_manager.sh" "zivpn.sh"
)

for file in "${CORE_FILES[@]}"; do
    wget -qO /etc/vps-manager/core/$file "$REPO_URL/core/$file"
done

# Permisos y limpieza obligatoria
chmod +x /usr/local/bin/menu
chmod +x /etc/vps-manager/core/*.sh
dos2unix /usr/local/bin/menu > /dev/null 2>&1
dos2unix /etc/vps-manager/core/*.sh > /dev/null 2>&1

echo -e "\n${C_GREEN}✅ ACTUALIZACIÓN COMPLETADA CON ÉXITO.${C_NC}"
sleep 2
menu
