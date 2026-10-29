#!/bin/bash
# ==========================================
# GOLBERT VPS PREMIUM - V5.0 LTS PANEL
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'; C_BLUE='\033[1;34m'; C_NC='\033[0m'

# ==========================================
# RUTA DE TUS SCRIPTS MÓDULOS
# ==========================================
DIR="/root" # Cambia a /etc/vps-manager si prefieres esa ruta

VERSION="v1.1"

if [ -f "$DIR/key_owner.txt" ]; then
    OWNER_NAME=$(cat $DIR/key_owner.txt)
else
    OWNER_NAME="Golbert VPS"
fi

get_system_info() {
    OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
    KERNEL_VER=$(uname -r)
    VPS_IP=$(curl -sS ifconfig.me || ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    DOMAIN=$(cat $DIR/domain.txt 2>/dev/null || echo "No configurado")
    CPU_USAGE=$(top -bn1 | grep load | awk '{printf "%.2f%%", $(NF-2)}')
    RAM_USAGE=$(free -m | awk 'NR==2{printf "%s / %s MB", $3, $2}')
    RAM_PERC=$(free -m | awk 'NR==2{printf "%d", $3*100/$2}')
    USERS_ACT=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)
}

check_services() {
    systemctl is-active --quiet ssh && SSH_ST="${C_GREEN}ON${C_NC}" || SSH_ST="${C_RED}OFF${C_NC}"
    systemctl is-active --quiet nginx && NGINX_ST="${C_GREEN}ON${C_NC}" || NGINX_ST="${C_RED}OFF${C_NC}"
    systemctl is-active --quiet xray && XRAY_ST="${C_GREEN}ON${C_NC}" || XRAY_ST="${C_RED}OFF${C_NC}"
    systemctl is-active --quiet stunnel4 && STUNNEL_ST="${C_GREEN}ON${C_NC}" || STUNNEL_ST="${C_RED}OFF${C_NC}"
    systemctl is-active --quiet ws-python && WS_ST="${C_GREEN}ON${C_NC}" || WS_ST="${C_RED}OFF${C_NC}"
    systemctl is-active --quiet hysteria && HCR_ST="${C_GREEN}ON${C_NC}" || HCR_ST="${C_RED}OFF${C_NC}"
}

while true; do
    get_system_info
    check_services
    clear

    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 🌟 ${C_YELLOW}GOLBERT VPS PREMIUM - V5.0 LTS PANEL${C_NC} 🌟"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " Key: ${C_GREEN}Verified [ $OWNER_NAME ]${C_NC} ${C_YELLOW}($VERSION)${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 💻 OS       : $OS_NAME"
    echo -e " ⚙️  Kernel   : $KERNEL_VER"
    echo -e " 🌐 IP       : $VPS_IP"
    echo -e " 🎯 Domain   : $DOMAIN"
    echo -e " 🧠 CPU Usage: [████████            ] $CPU_USAGE"
    echo -e " ⚡ RAM Usage: [██████████          ] $RAM_PERC% ($RAM_USAGE)"
    echo -e " 👥 Users    : $USERS_ACT Creados | 0 En Línea"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " SSH : $SSH_ST    NGINX : $NGINX_ST    XRAY : $XRAY_ST"
    echo -e " STUNNEL : $STUNNEL_ST SSH-WS : $WS_ST    HCR : $HCR_ST"
    echo -e "${C_CYAN}================================================${C_NC}"
    
    echo -e "\n ${C_YELLOW}[ ACCOUNT MANAGEMENT ]${C_NC}"
    echo -e "  1. 👤 SSH Management (Users, Limit, HWID)"
    echo -e "  2. 🤝 Reseller Management (Credits)"
    
    echo -e "\n ${C_YELLOW}[ TOOLS & SYSTEM ]${C_NC}"
    echo -e "  3. 🛠️ Installers & Protocols Manager"
    echo -e "  4. 🎨 Configure HTML Welcome Banner"
    echo -e "  5. 🔍 Ports Monitor (Active / Inactive)"
    echo -e "  6. ⚙️ Domain Manager & SSL Certificates"
    echo -e "  7. 🤖 Link Telegram Bot"
    echo -e "  8. 🌐 Generate Web Panel (Dashboard UI)"
    echo -e "  9. 🔄 Update Panel (From GitHub)"
    echo -e " 10. 🚀 Enable Auto-Start on Login"
    echo -e " 11. 💻 VPS Specifications & Capacity"
    echo -e " 12. 🛡️ Firewall Manager (Rules & Security)"
    echo -e " 13. 👥 Install CheckUser (Multi-App Monitor)"
    echo -e " 14. 🌍 Change Language (ES/EN)"
    echo -e " 15. 🔧 Repair / Fix Ports (Nginx Gateway)"
    
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " ${C_RED}88.${C_NC} ❌ Uninstall Script   ${C_CYAN}|${C_NC}   ${C_RED}0.${C_NC} 🚪 Exit"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " ${C_CYAN}Soporte Telegram :${C_NC} @golbert_service"
    echo -e " ${C_CYAN}WhatsApp Oficial :${C_NC} +51960084993"
    echo -e "${C_CYAN}================================================${C_NC}"
    
    read -p " Select an option: " opcion
    
    case $opcion in
        1) bash $DIR/user.sh ;;
        2) bash $DIR/reseller.sh ;;
        3) bash $DIR/installers.sh ;;
        4) nano $DIR/banner.html ;;
        5) bash $DIR/ports.sh ;;
        6) bash $DIR/domain.sh ;;
        7) bash $DIR/bot.sh ;;
        8) bash $DIR/webpanel.sh ;;
        9) bash $DIR/update.sh ;;
        10) bash $DIR/autostart.sh ;;
        11) bash $DIR/specs.sh ;;
        12) bash $DIR/firewall.sh ;;
        13) bash $DIR/checkuser.sh ;;
        14) bash $DIR/language.sh ;;
        15) bash $DIR/fix_ports.sh ;;
        88) bash $DIR/uninstall.sh ;;
        0) clear; exit 0 ;;
        *) echo -e "${C_RED}Opción inválida.${C_NC}"; sleep 2 ;;
    esac
done
