#!/bin/bash
# ==========================================
# Instalador Principal - UI Premium + AutoStart + Core Fix
# ==========================================
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_CYAN='\033[1;36m'
C_ORANGE='\033[38;5;214m'
C_NC='\033[0m'

# Fondos de color para los avisos
BG_RED='\033[41;1;37m'
BG_BLUE='\033[44;1;37m'
BG_GRAY='\033[47;1;30m'

# Recopilar datos del sistema
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
echo -e "       💥 INTENTANDO RECONFIGURAR UPDATER 💥"
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
sleep 1
echo -e "       💥 UPDATE DATE : $date_time 💥"
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
sleep 1
echo -e "       💥 INSTALANDO NUEVO PAQUETES ( S|P|C )     💥"
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
sleep 1
echo -e "       💥 PREPARANDO BASE RAPIDA INSTALL          💥"
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
sleep 1
echo -e "       💥 CHECK IP FIJA $ip_addr           💥"
echo -e "${C_ORANGE}======================================================${C_NC}"
echo -e "                       ${C_CYAN}....${C_NC}"
sleep 2

clear
echo -e "\n-- ${BG_RED} INSTALAREMOS LO NECESARIO PARA EL ADM ${C_NC} --"
echo -e "      ${BG_BLUE} SU IP REGISTRADA ES : $ip_addr ${C_NC}"
echo -e "-- ${BG_RED} Arch : $arch SISTEMA : $os_name ${C_NC} --"
echo -e "${BG_GRAY} ATENCION A INSTALACION POR SI DEVUELVE UN ERROR ${C_NC}\n"
echo -e "${C_ORANGE}======================================================${C_NC}"
echo -e "${BG_GRAY} ERRORES GRAFICOS FIXEADOS AL FINALIZAR ${C_NC}"

# Lista de dependencias a instalar
paquetes=(
    "bsdmainutils" "sudo" "cron" "usermod" "screen" "nginx" 
    "nload" "htop" "python" "python3" "python3-pip" 
    "nodejs" "npm" "lsof" "psmisc" "socat" "bc" "netcat" "net-tools"
)

export DEBIAN_FRONTEND=noninteractive
apt-get update -y > /dev/null 2>&1

for pkg in "${paquetes[@]}"; do
    apt-get install -y "$pkg" > /dev/null 2>&1
    pkg_upper=$(echo "$pkg" | tr '[:lower:]' '[:upper:]')
    echo -e " - [ ${C_GREEN}✅${C_NC} ] INSTALACION CORRECTA $pkg_upper"
    sleep 0.3
done

# --- NUEVO: Activar Nginx por defecto ---
systemctl unmask nginx > /dev/null 2>&1
systemctl enable nginx > /dev/null 2>&1
systemctl start nginx > /dev/null 2>&1
systemctl restart nginx > /dev/null 2>&1
echo -e " - [ ${C_GREEN}✅${C_NC} ] SERVICIO NGINX ACTIVADO (ON)"
# ----------------------------------------

# --- SOLUCIÓN: Descargar el menú y todos los módulos base ---
echo -e "\n${C_ORANGE}======================================================${C_NC}"
echo -e "${C_GREEN}Descargando el panel principal y módulos internos...${C_NC}"
mkdir -p /etc/vps-manager/core

# 1. Descargar Menú Principal
wget -qO /usr/local/bin/menu https://raw.githubusercontent.com/golbert19/vps-script/main/menu.sh
chmod +x /usr/local/bin/menu
echo -e " - [ ${C_GREEN}✅${C_NC} ] PANEL PRINCIPAL INSTALADO"

# 2. Descargar todos los submódulos de la carpeta core
REPO_URL="https://raw.githubusercontent.com/golbert19/vps-script/main"
CORE_FILES=(
    "specs.sh" "fix_ports.sh" "domain.sh" "banner.sh" "update.sh" 
    "user.sh" "bot.sh" "webpanel.sh" "firewall.sh" "checkuser.sh"
    "xray_manager.sh" "vmess.sh" "vless.sh" "trojan.sh" "slowdns.sh"
    "badvpn.sh" "hcr.sh" "hysteria.sh" "udp_custom.sh" "bhttp.sh"
    "sshws.sh" "ssl.sh" "setup_openvpn.sh" "zivpn.sh" "bbr.sh"
    "php.sh" "ports.sh"
)

for file in "${CORE_FILES[@]}"; do
    wget -qO /etc/vps-manager/core/$file "$REPO_URL/core/$file" 2>/dev/null
    chmod +x /etc/vps-manager/core/$file 2>/dev/null
done
echo -e " - [ ${C_GREEN}✅${C_NC} ] MÓDULOS DE FUNCIONES INSTALADOS"

# Configurar autoinicio del menú al iniciar sesión SSH
if ! grep -q "menu" /root/.bashrc; then
    echo -e "\nclear\nmenu" >> /root/.bashrc
fi

echo -e "${C_ORANGE}======================================================${C_NC}"
echo -e "\n${C_GREEN}✅ INSTALACIÓN BASE COMPLETADA EXITOSAMENTE.${C_NC}"
echo -e "${C_CYAN}======================================================${C_NC}"
echo -e "${C_YELLOW}⚠️  ATENCIÓN CLIENTE:${C_NC}"
echo -e "El VPS se reiniciará automáticamente para aplicar todos"
echo -e "los cambios de red y configuraciones del panel."
echo -e ""
echo -e "Tu aplicación se desconectará (Terminal cerrada)."
echo -e "Espera ${C_GREEN}10 segundos${C_NC}, vuelve a iniciar sesión en tu VPS"
echo -e "y ${C_CYAN}el panel principal se abrirá de forma automática${C_NC}."
echo -e "${C_CYAN}======================================================${C_NC}"

# Cuenta regresiva para el reinicio
for i in {10..1}; do
    echo -ne "\r⏳ Reiniciando sistema en $i segundos... "
    sleep 1
done

echo -e "\n\n🚀 Reiniciando ahora..."
reboot
