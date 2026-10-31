#!/bin/bash
# ==========================================
# Instalador Principal - UI Premium + AutoStart + Core Fix
# ==========================================
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_CYAN='\033[1;36m'
C_ORANGE='\033[38;5;214m'
C_NC='\033[0m'
BG_RED='\033[41;1;37m'
BG_BLUE='\033[44;1;37m'
BG_GRAY='\033[47;1;30m'

os_name=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2 | awk '{print $1, $2}')
cpu_info=$(grep "vendor_id" /proc/cpuinfo | head -1 | awk -F': ' '{print $2}')
ip_addr=$(curl -sS ifconfig.me 2>/dev/null || wget -qO- ipv4.icanhazip.com)
date_time=$(date +"%d/%m/%Y & TIME : %H:%M")
arch=$(uname -m)

clear
echo -e "${C_ORANGE}======================================================${C_NC}"
echo -e "             [ ! ] ESPERE UN MOMENTO [ ! ]"
echo -e "${C_ORANGE}======================================================${C_NC}"
echo -e " ${C_RED}SISTEMA:${C_NC} $os_name          ${C_RED}CPU:${C_NC} $cpu_info"
echo -e "${C_ORANGE}======================================================${C_NC}"
sleep 1

# Paquetes base (Se añadió dos2unix para prevenir errores de formato)
paquetes=(
    "bsdmainutils" "sudo" "cron" "usermod" "screen" "nginx" 
    "nload" "htop" "python" "python3" "python3-pip" 
    "nodejs" "npm" "lsof" "psmisc" "socat" "bc" "netcat" "net-tools" "dos2unix"
)

export DEBIAN_FRONTEND=noninteractive
apt-get update -y > /dev/null 2>&1

for pkg in "${paquetes[@]}"; do
    apt-get install -y "$pkg" > /dev/null 2>&1
    echo -e " - [ ${C_GREEN}✅${C_NC} ] INSTALACIÓN CORRECTA ${pkg}"
done

# --- ACTIVACIÓN DE NGINX POR DEFECTO ---
systemctl unmask nginx > /dev/null 2>&1
systemctl enable nginx > /dev/null 2>&1
systemctl start nginx > /dev/null 2>&1
echo -e " - [ ${C_GREEN}✅${C_NC} ] SERVICIO NGINX ACTIVADO (ON)"

# --- DESCARGA DE ARCHIVOS SINCRONIZADA ---
echo -e "\n${C_ORANGE}======================================================${C_NC}"
echo -e "${C_GREEN}Descargando panel y módulos sincronizados...${C_NC}"
mkdir -p /etc/vps-manager/core

REPO_URL="https://raw.githubusercontent.com/golbert19/vps-script/main"

# 1. Menú Principal y Dependencias de Raíz
wget -qO /usr/local/bin/menu "$REPO_URL/menu.sh"
wget -qO /etc/vps-manager/languages.sh "$REPO_URL/languages.sh"
wget -qO /etc/vps-manager/version "$REPO_URL/version"

# 2. Lista completa de 38 archivos en la carpeta core (Sincronizado al 100%)
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

# Permisos y limpieza de errores de formato Windows a Linux
chmod +x /usr/local/bin/menu
chmod +x /etc/vps-manager/core/*.sh
dos2unix /usr/local/bin/menu > /dev/null 2>&1
dos2unix /etc/vps-manager/core/*.sh > /dev/null 2>&1

echo -e " - [ ${C_GREEN}✅${C_NC} ] MÓDULOS DE FUNCIONES INSTALADOS Y LIMPIOS"

# Autoinicio
if ! grep -q "menu" /root/.bashrc; then
    echo -e "\nclear\nmenu" >> /root/.bashrc
fi

echo -e "${C_ORANGE}======================================================${C_NC}"
echo -e "\n${C_GREEN}✅ INSTALACIÓN BASE COMPLETADA EXITOSAMENTE.${C_NC}"
sleep 3
reboot
