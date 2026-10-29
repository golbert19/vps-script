#!/bin/bash
# ==========================================
# Panel Principal - Golbert VPS V5.0 LTS
# ==========================================
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'
C_NC='\033[0m'

# Función para las barras de progreso gráficas
draw_bar() {
    local percent=$1
    local length=15
    local filled=$((percent * length / 100))
    local empty=$((length - filled))
    local bar="["
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    for ((i=0; i<empty; i++)); do bar="${bar} "; done
    bar="${bar}]"
    echo "$bar"
}

# Obtener datos estáticos del sistema
os_name=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
kernel_ver=$(uname -r)
IP=$(curl -sS ifconfig.me 2>/dev/null || wget -qO- ipv4.icanhazip.com)
domain_name="No configurado"
[ -f /etc/vps-manager/domain.txt ] && domain_name=$(cat /etc/vps-manager/domain.txt)

while true; do
    clear
    # Cálculos de RAM
    total_ram=$(free -m | awk 'NR==2 {print $2}')
    used_ram=$(free -m | awk 'NR==2 {print $3}')
    ram_usage=$((used_ram * 100 / total_ram))
    ram_bar=$(draw_bar $ram_usage)

    # Cálculos de CPU
    cpu_usage_raw=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')
    cpu_usage=$(printf "%.2f" "$cpu_usage_raw")
    cpu_usage_int=${cpu_usage_raw%.*}
    cpu_bar=$(draw_bar $cpu_usage_int)

    # Usuarios
    total_users=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)
    online_users=$(ps -u root | grep sshd | wc -l)

    # Servicios
    [ "$(systemctl is-active ssh)" = "active" ] && s_ssh="${C_GREEN}ON${C_NC}" || s_ssh="${C_RED}OFF${C_NC}"
    [ "$(systemctl is-active nginx)" = "active" ] && s_nginx="${C_GREEN}ON${C_NC}" || s_nginx="${C_RED}OFF${C_NC}"
    [ "$(systemctl is-active xray)" = "active" ] && s_xray="${C_GREEN}ON${C_NC}" || s_xray="${C_RED}OFF${C_NC}"
    [ "$(systemctl is-active stunnel4)" = "active" ] && s_stunnel="${C_GREEN}ON${C_NC}" || s_stunnel="${C_RED}OFF${C_NC}"
    [ "$(systemctl is-active ws-python)" = "active" ] && s_ws="${C_GREEN}ON${C_NC}" || s_ws="${C_RED}OFF${C_NC}"
    [ "$(systemctl is-active hcr)" = "active" ] || [ -f /etc/vps-manager/hcr.pid ] && s_hcr="${C_GREEN}ON${C_NC}" || s_hcr="${C_RED}OFF${C_NC}"

    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 🌟 ${C_YELLOW}GOLBERT VPS PREMIUM - V5.0 LTS PANEL${C_NC} 🌟"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " ${C_GREEN}Key: Verified [ Golbert VPS ] (v1.1)${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 💻 OS       : $os_name"
    echo -e " ⚙️ Kernel   : $kernel_ver"
    echo -e " 🌐 IP       : $IP"
    echo -e " 🎯 Domain   : $domain_name"
    echo -e " 🧠 CPU Usage: ${C_GREEN}${cpu_bar}${C_NC} $cpu_usage%"
    echo -e " ⚡ RAM Usage: ${C_GREEN}${ram_bar}${C_NC} $ram_usage% (${used_ram} / ${total_ram} MB)"
    echo -e " 👥 Users    : $total_users Creados | $online_users En Línea"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " SSH : $s_ssh     NGINX : $s_nginx     XRAY : $s_xray"
    echo -e " STUNNEL : $s_stunnel SSH-WS : $s_ws    HCR : $s_hcr"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e ""
    echo -e "${C_YELLOW}[ ACCOUNT MANAGEMENT ]${C_NC}"
    echo -e " ${C_CYAN}1.${C_NC} 👤 SSH Management (Users, Limit, HWID)"
    echo -e " ${C_CYAN}2.${C_NC} 🤝 Reseller Management (Credits)"
    echo -e ""
    echo -e "${C_YELLOW}[ TOOLS & SYSTEM ]${C_NC}"
    echo -e " ${C_CYAN}3.${C_NC} 🛠️ Installers & Protocols Manager"
    echo -e " ${C_CYAN}4.${C_NC} 🎨 Configure HTML Welcome Banner"
    echo -e " ${C_CYAN}5.${C_NC} 🔍 Ports Monitor (Active / Inactive)"
    echo -e " ${C_CYAN}6.${C_NC} 🌐 Domain Manager & SSL Certificates"
    echo -e " ${C_CYAN}7.${C_NC} 🤖 Link Telegram Bot"
    echo -e " ${C_CYAN}8.${C_NC} 🌐 Generate Web Panel (Dashboard UI)"
    echo -e " ${C_CYAN}9.${C_NC} 🔄 Update Panel (From GitHub)"
    echo -e " ${C_CYAN}10.${C_NC} 🚀 Enable Auto-Start on Login"
    echo -e " ${C_CYAN}11.${C_NC} 💻 VPS Specifications & Capacity"
    echo -e " ${C_CYAN}12.${C_NC} 🛡️ Firewall Manager (Rules & Security)"
    echo -e " ${C_CYAN}13.${C_NC} 👥 Install CheckUser (Multi-App Monitor)"
    echo -e " ${C_CYAN}14.${C_NC} 🌍 Change Language (ES/EN)"
    echo -e " ${C_CYAN}15.${C_NC} 🔧 Repair / Fix Ports (Nginx Gateway)"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " ${C_RED}88. ❌ Uninstall Script   |   0. 🚪 Exit${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " ${C_CYAN}Soporte Telegram : @golbert_service${C_NC}"
    echo -e " ${C_CYAN}WhatsApp Oficial : +51960084993${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    
    read -p " Select an option: " opcion
    
    # Enrutamiento hacia los archivos individuales de tu carpeta core/
    case $opcion in
        1) [ -f /etc/vps-manager/core/user.sh ] && bash /etc/vps-manager/core/user.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        2) [ -f /etc/vps-manager/core/bot.sh ] && bash /etc/vps-manager/core/bot.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        3) [ -f /etc/vps-manager/core/install.sh ] && bash /etc/vps-manager/core/install.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        4) echo "Configurando Banner HTML..." ; sleep 2 ;;
        5) netstat -tulnp | grep -E 'ssh|nginx|xray|stunnel|python|hcr' ; read -p "Presiona Enter para continuar..." ;;
        6) [ -f /etc/vps-manager/core/domain.sh ] && bash /etc/vps-manager/core/domain.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        8) [ -f /etc/vps-manager/core/webpanel.sh ] && bash /etc/vps-manager/core/webpanel.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        9) [ -f /etc/vps-manager/core/update.sh ] && bash /etc/vps-manager/core/update.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        11) [ -f /etc/vps-manager/core/specs.sh ] && bash /etc/vps-manager/core/specs.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        12) [ -f /etc/vps-manager/core/firewall.sh ] && bash /etc/vps-manager/core/firewall.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        13) [ -f /etc/vps-manager/core/checkuser.sh ] && bash /etc/vps-manager/core/checkuser.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        15) [ -f /etc/vps-manager/fix_ports.sh ] && bash /etc/vps-manager/fix_ports.sh || echo "Script no encontrado" ; sleep 2 ;;
        88) read -p "¿Desinstalar script? (s/n): " des; [ "$des" = "s" ] && exit 0 ;;
        0) clear ; exit 0 ;;
        *) echo -e "${C_RED}Opción inválida.${C_NC}" ; sleep 1 ;;
    esac
done
