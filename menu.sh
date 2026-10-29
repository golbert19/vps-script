#!/bin/bash
# ==========================================
# GOLBERT VPS PREMIUM - V5.0 LTS PANEL
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'; C_BLUE='\033[1;34m'; C_WHITE='\033[1;37m'; C_NC='\033[0m'

DIR="/root"
CORE="/root/core"
VERSION="v5.0 LTS"

if [ -f "$DIR/key_owner.txt" ]; then
    OWNER_NAME=$(cat "$DIR/key_owner.txt")
else
    OWNER_NAME="Golbert VPS"
fi

# Función segura para ejecutar scripts existentes
run_script() {
    local target="$1"
    if [ -f "$target" ]; then
        chmod +x "$target"
        bash "$target"
    else
        echo -e "\n${C_RED}[ERROR] No se encontró el archivo: $target${C_NC}"
        sleep 2
    fi
}

get_system_info() {
    OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
    KERNEL_VER=$(uname -r)
    VPS_IP=$(curl -sS --max-time 2 ifconfig.me || hostname -I | awk '{print $1}')
    DOMAIN=$(cat "$DIR/domain.txt" 2>/dev/null || cat /etc/xray/domain 2>/dev/null || echo "No configurado")
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.1f%%", 100 - $8}')
    RAM_USAGE=$(free -m | awk 'NR==2{printf "%s / %s MB", $3, $2}')
    RAM_PERC=$(free -m | awk 'NR==2{printf "%d", $3*100/$2}')
    USERS_ACT=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)
    USERS_ON=$(ps aux | grep "sshd:" | grep -v "grep" | grep -v "root" | wc -l)
}

check_services() {
    systemctl is-active --quiet ssh || systemctl is-active --quiet sshd && SSH_ST="${C_GREEN}ON${C_NC}" || SSH_ST="${C_RED}OFF${C_NC}"
    systemctl is-active --quiet nginx && NGINX_ST="${C_GREEN}ON${C_NC}" || NGINX_ST="${C_RED}OFF${C_NC}"
    systemctl is-active --quiet xray && XRAY_ST="${C_GREEN}ON${C_NC}" || XRAY_ST="${C_RED}OFF${C_NC}"
    systemctl is-active --quiet stunnel4 && STUNNEL_ST="${C_GREEN}ON${C_NC}" || STUNNEL_ST="${C_RED}OFF${C_NC}"
    (systemctl is-active --quiet ws-python || systemctl is-active --quiet sshws || systemctl is-active --quiet websocket) && WS_ST="${C_GREEN}ON${C_NC}" || WS_ST="${C_RED}OFF${C_NC}"
    (systemctl is-active --quiet hcr || systemctl is-active --quiet hysteria || pgrep -f "hcr-server" >/dev/null) && HCR_ST="${C_GREEN}ON${C_NC}" || HCR_ST="${C_RED}OFF${C_NC}"
}

# ==========================================
# SUBMENÚ 1: GESTIÓN DE CUENTAS SSH / OVPN
# ==========================================
submenu_ssh() {
    while true; do
        clear
        echo -e "${C_CYAN}================================================${C_NC}"
        echo -e " 👤 ${C_YELLOW}SSH & OPENVPN ACCOUNT MANAGEMENT${C_NC}"
        echo -e "${C_CYAN}================================================${C_NC}"
        echo -e "  1. Crear / Gestionar Usuarios SSH (user.sh)"
        echo -e "  2. Panel Avanzado SSH / HWID (core/ssh.sh)"
        echo -e "  3. Limitador de Conexiones / Multilogin (core/limiter.sh)"
        echo -e "  4. Generar Perfil de Usuario OpenVPN (core/add_ovpn_user.sh)"
        echo -e "  0. Volver al Menú Principal"
        echo -e "${C_CYAN}================================================${C_NC}"
        echo -en "${C_GREEN} Selecciona una opción: ${C_NC}"
        read -r sub1
        case $sub1 in
            1) [ -f "$DIR/user.sh" ] && run_script "$DIR/user.sh" || run_script "$CORE/ssh.sh" ;;
            2) run_script "$CORE/ssh.sh" ;;
            3) run_script "$CORE/limiter.sh" ;;
            4) run_script "$CORE/add_ovpn_user.sh" ;;
            0) break ;;
            *) echo -e "${C_RED}Opción inválida${C_NC}"; sleep 1 ;;
        esac
    done
}

# ==========================================
# SUBMENÚ 2: GESTIÓN DE REVENDEDORES
# ==========================================
submenu_reseller() {
    while true; do
        clear
        echo -e "${C_CYAN}================================================${C_NC}"
        echo -e " 🤝 ${C_YELLOW}RESELLER MANAGEMENT (CREDITS & BOT)${C_NC}"
        echo -e "${C_CYAN}================================================${C_NC}"
        echo -e "  1. Administrar Bot de Revendedores y Créditos (core/bot.sh)"
        echo -e "  2. Administrar Usuarios desde Panel Web (core/webpanel.sh)"
        echo -e "  0. Volver al Menú Principal"
        echo -e "${C_CYAN}================================================${C_NC}"
        echo -en "${C_GREEN} Selecciona una opción: ${C_NC}"
        read -r sub2
        case $sub2 in
            1) run_script "$CORE/bot.sh" ;;
            2) run_script "$CORE/webpanel.sh" ;;
            0) break ;;
            *) echo -e "${C_RED}Opción inválida${C_NC}"; sleep 1 ;;
        esac
    done
}

# ==========================================
# SUBMENÚ 3: INSTALADORES Y PROTOCOLOS (CORE)
# ==========================================
submenu_installers() {
    while true; do
        clear
        echo -e "${C_CYAN}================================================${C_NC}"
        echo -e " 🛠️  ${C_YELLOW}INSTALLERS & PROTOCOLS MANAGER${C_NC}"
        echo -e "${C_CYAN}================================================${C_NC}"
        echo -e "  1. 📦 Xray Multi-Protocol Manager (xray_manager.sh)"
        echo -e "  2. ⚡ VMess Dual Ports (vmess.sh)"
        echo -e "  3. ⚡ VLESS Protocol (vless.sh)"
        echo -e "  4. 🔒 Trojan Port 443 (trojan.sh)"
        echo -e "  5. 🐢 SlowDNS V5.0 LTS (Slowdns.sh)"
        echo -e "  6. 🎮 BadVPN UDPGW 7200/7300 (badvpn.sh)"
        echo -e "  7. 🚀 HCR Nativo Port 8880 (hcr.sh)"
        echo -e "  8. 🔥 Hysteria / Hysteria 2 UDP (hysteria.sh / setup_hysteria.sh)"
        echo -e "  9. 🎯 UDP Custom Port 2000/25000 (udp_custom.sh)"
        echo -e " 10. 🌐 BHTTP Proxy Port 8080 (bhttp.sh)"
        echo -e " 11. 🔌 SSH WebSocket Python (sshws.sh / websocket.sh)"
        echo -e " 12. 🔐 SSL/TLS Stunnel Proxy (ssl.sh)"
        echo -e " 13. 🛡️  OpenVPN Server Setup (setup_openvpn.sh)"
        echo -e " 14. 📲 ZiVPN UDP Manager (zivpn.sh / setup_zivpn.sh)"
        echo -e " 15. ⚙️  TCP BBR Optimizer (Bbr.sh)"
        echo -e "  0. 🚪 Volver al Menú Principal"
        echo -e "${C_CYAN}================================================${C_NC}"
        echo -en "${C_GREEN} Selecciona el protocolo a instalar/gestionar: ${C_NC}"
        read -r proto
        case $proto in
            1) run_script "$CORE/xray_manager.sh" ;;
            2) run_script "$CORE/vmess.sh" ;;
            3) run_script "$CORE/vless.sh" ;;
            4) run_script "$CORE/trojan.sh" ;;
            5) run_script "$CORE/Slowdns.sh" ;;
            6) run_script "$CORE/badvpn.sh" ;;
            7) run_script "$CORE/hcr.sh" ;;
            8) 
               echo -e "\n 1) Hysteria 1 (hysteria.sh)\n 2) Hysteria 2 (setup_hysteria.sh)"
               read -p " Opción: " hopt
               [ "$hopt" = "2" ] && run_script "$CORE/setup_hysteria.sh" || run_script "$CORE/hysteria.sh"
               ;;
            9) run_script "$CORE/udp_custom.sh" ;;
            10) run_script "$CORE/bhttp.sh" ;;
            11) 
               echo -e "\n 1) SSH-WS (sshws.sh)\n 2) WebSocket Manager (websocket.sh)"
               read -p " Opción: " wsopt
               [ "$wsopt" = "2" ] && run_script "$CORE/websocket.sh" || run_script "$CORE/sshws.sh"
               ;;
            12) run_script "$CORE/ssl.sh" ;;
            13) run_script "$CORE/setup_openvpn.sh" ;;
            14) 
               echo -e "\n 1) ZiVPN Manager (zivpn.sh)\n 2) Instalar ZiVPN (setup_zivpn.sh)"
               read -p " Opción: " zopt
               [ "$zopt" = "2" ] && run_script "$CORE/setup_zivpn.sh" || run_script "$CORE/zivpn.sh"
               ;;
            15) run_script "$CORE/Bbr.sh" ;;
            0) break ;;
            *) echo -e "${C_RED}Opción inválida${C_NC}"; sleep 1 ;;
        esac
    done
}

# ==========================================
# SUBMENÚ 5: MONITOR DE PUERTOS
# ==========================================
submenu_ports() {
    clear
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 🔍 ${C_YELLOW}PORTS MONITOR (ACTIVE / LISTENING)${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    printf " %-8s %-20s %-15s\n" "PROTO" "PUERTO LOCAL" "SERVICIO/PROCESO"
    echo -e "${C_CYAN}------------------------------------------------${C_NC}"
    ss -tulpn | awk 'NR>1 {
        split($5, a, ":"); port=a[length(a)];
        proc=$7; gsub(/users:\(\("/, "", proc); gsub(/".*/, "", proc);
        if(port != "") printf " %-8s %-20s %-15s\n", $1, port, proc
    }' | sort -u -k2,2n
    echo -e "${C_CYAN}================================================${C_NC}"
    read -p " Presiona [Enter] para volver al menú..."
}

# ==========================================
# SUBMENÚ 6: DOMINIO Y CLOUDFLARE DNS
# ==========================================
submenu_domain() {
    while true; do
        clear
        echo -e "${C_CYAN}================================================${C_NC}"
        echo -e " ⚙️  ${C_YELLOW}DOMAIN MANAGER & SSL CERTIFICATES${C_NC}"
        echo -e "${C_CYAN}================================================${C_NC}"
        echo -e "  1. Configurar Dominio y Certificado SSL (core/domain.sh)"
        echo -e "  2. Automatización DNS Cloudflare (core/setup_dns.sh)"
        echo -e "  0. Volver al Menú Principal"
        echo -e "${C_CYAN}================================================${C_NC}"
        echo -en "${C_GREEN} Selecciona una opción: ${C_NC}"
        read -r domopt
        case $domopt in
            1) run_script "$CORE/domain.sh" ;;
            2) run_script "$CORE/setup_dns.sh" ;;
            0) break ;;
            *) echo -e "${C_RED}Opción inválida${C_NC}"; sleep 1 ;;
        esac
    done
}

# ==========================================
# BUCLE PRINCIPAL DEL MENÚ
# ==========================================
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
    echo -e " 🧠 CPU Usage: $CPU_USAGE"
    echo -e " ⚡ RAM Usage: $RAM_PERC% ($RAM_USAGE)"
    echo -e " 👥 Users    : $USERS_ACT Creados | $USERS_ON En Línea"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " SSH : $SSH_ST    NGINX : $NGINX_ST    XRAY : $XRAY_ST"
    echo -e " STUNNEL : $STUNNEL_ST SSH-WS : $WS_ST    HCR : $HCR_ST"
    echo -e "${C_CYAN}================================================${C_NC}"
    
    echo -e "\n ${C_YELLOW}[ ACCOUNT MANAGEMENT ]${C_NC}"
    echo -e "  1. 👤 SSH Management (Users, Limit, HWID)"
    echo -e "  2. 🤝 Reseller Management (Credits)"
    
    echo -e "\n ${C_YELLOW}[ TOOLS & SYSTEM ]${C_NC}"
    echo -e "  3. 🛠️  Installers & Protocols Manager"
    echo -e "  4. 🎨 Configure HTML Welcome Banner"
    echo -e "  5. 🔍 Ports Monitor (Active / Inactive)"
    echo -e "  6. ⚙️  Domain Manager & SSL Certificates"
    echo -e "  7. 🤖 Link Telegram Bot"
    echo -e "  8. 🌐 Generate Web Panel (Dashboard UI)"
    echo -e "  9. 🔄 Update Panel (From GitHub)"
    echo -e " 10. 🚀 Enable Auto-Start on Login"
    echo -e " 11. 💻 VPS Specifications & Capacity"
    echo -e " 12. 🛡️  Firewall Manager (Rules & Security)"
    echo -e " 13. 👥 Install CheckUser (Multi-App Monitor)"
    echo -e " 14. 🌍 Change Language (ES/EN)"
    echo -e " 15. 🔧 Repair / Fix Ports (Nginx Gateway)"
    
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " ${C_RED}88.${C_NC} ❌ Uninstall Script   ${C_CYAN}|${C_NC}   ${C_RED}0.${C_NC} 🚪 Exit"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " ${C_CYAN}Soporte Telegram :${C_NC} @golbert_service"
    echo -e " ${C_CYAN}WhatsApp Oficial :${C_NC} +51960084993"
    echo -e "${C_CYAN}================================================${C_NC}"
    
    echo -en "\033[1;32m Select an option: \033[0m"
    read -r opcion
    
    case $opcion in
        1) submenu_ssh ;;
        2) submenu_reseller ;;
        3) submenu_installers ;;
        4) 
           BANNER_FILE="/etc/issue.net"
           [ -f "$DIR/banner.html" ] && BANNER_FILE="$DIR/banner.html"
           nano "$BANNER_FILE"
           systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
           ;;
        5) submenu_ports ;;
        6) submenu_domain ;;
        7) run_script "$CORE/bot.sh" ;;
        8) run_script "$CORE/webpanel.sh" ;;
        9) run_script "$CORE/update.sh" ;;
        10)
           if grep -q "menu.sh" /root/.bashrc; then
               sed -i '/menu.sh/d' /root/.bashrc
               echo -e "\n${C_YELLOW}Auto-inicio desactivado.${C_NC}"
           else
               echo "/root/menu.sh" >> /root/.bashrc
               echo -e "\n${C_GREEN}Auto-inicio activado al iniciar sesión.${C_NC}"
           fi
           sleep 1.5
           ;;
        11) run_script "$DIR/specs.sh" ;;
        12) run_script "$CORE/firewall.sh" ;;
        13) run_script "$CORE/checkuser.sh" ;;
        14)
           echo -e "\n${C_GREEN}Idioma configurado: Español / English Ready.${C_NC}"
           sleep 1.5
           ;;
        15) run_script "$DIR/fix_ports.sh" ;;
        88)
           echo -en "\n${C_RED}¿Confirmas desinstalar Golbert VPS Panel? (s/n): ${C_NC}"
           read -r confirm
           if [[ "$confirm" =~ ^[sS]$ ]]; then
               rm -rf "$CORE" "$DIR/menu.sh" "$DIR/specs.sh" "$DIR/user.sh" "$DIR/fix_ports.sh"
               sed -i '/menu.sh/d' /root/.bashrc
               echo -e "${C_GREEN}Panel desinstalado correctamente.${C_NC}"
               exit 0
           fi
           ;;
        0) clear; exit 0 ;;
        *) 
           echo -e "${C_RED}Opción inválida: $opcion${C_NC}"
           sleep 1
           ;;
    esac
done
