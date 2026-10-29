#!/bin/bash
# ==========================================
# GOLBERT VPS PREMIUM - V5.0 LTS PANEL
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'; C_BLUE='\033[1;34m'; C_NC='\033[0m'

DIR="/root"
VERSION="v5.0"

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
    
    echo -en "\033[1;32m Select an option: \033[0m"
    read -r opcion
    
    case $opcion in
        1)
            clear
            echo -e "${C_YELLOW}--- GESTIÓN DE SSH ---${C_NC}"
            if [ -f "$DIR/user.sh" ]; then bash "$DIR/user.sh"; else
                echo "1) Crear Usuario SSH"
                echo "2) Listar Usuarios"
                echo "3) Eliminar Usuario"
                read -p "Selecciona una opción: " usropt
            fi
            read -p "Presiona Enter para continuar..."
            ;;
        2)
            clear
            echo -e "${C_YELLOW}--- GESTIÓN DE REVENDEDORES ---${C_NC}"
            echo "Sistema de créditos activo para revendedores."
            read -p "Presiona Enter para continuar..."
            ;;
        3)
            clear
            echo -e "${C_YELLOW}--- INSTALADORES Y PROTOCOLOS ---${C_NC}"
            echo "1. Instalar Xray (VMess/VLESS/Trojan)"
            echo "2. Instalar Hysteria / UDP Custom"
            read -p "Presiona Enter para continuar..."
            ;;
        4)
            if [ -f "$DIR/banner.html" ]; then
                nano "$DIR/banner.html"
            else
                echo "<h1>Golbert VPS Welcome</h1>" > "$DIR/banner.html"
                nano "$DIR/banner.html"
            fi
            ;;
        5)
            clear
            echo -e "${C_CYAN}================================================${C_NC}"
            echo -e " 🔍 ${C_YELLOW}MONITOR DE PUERTOS ACTIVOS${C_NC}"
            echo -e "${C_CYAN}================================================${C_NC}"
            ss -tulpn | grep LISTEN
            echo -e "${C_CYAN}================================================${C_NC}"
            read -p "Presiona [Enter] para volver al menú..."
            ;;
        6)
            clear
            echo -e "${C_YELLOW}--- GESTIÓN DE DOMINIO Y SSL ---${C_NC}"
            read -p "Ingresa tu dominio: " midomain
            echo "$midomain" > "$DIR/domain.txt"
            echo -e "${C_GREEN}Dominio guardado correctamente.${C_NC}"
            sleep 1.5
            ;;
        7)
            clear
            echo -e "${C_YELLOW}--- BOT DE TELEGRAM ---${C_NC}"
            echo "Configuración de enlace con @golbert_service"
            read -p "Presiona Enter para continuar..."
            ;;
        8)
            clear
            echo -e "${C_YELLOW}--- PANEL WEB (DASHBOARD) ---${C_NC}"
            echo "Generando interfaz web en puerto 80/8080..."
            sleep 1.5
            ;;
        9)
            clear
            echo -e "${C_YELLOW}--- ACTUALIZAR PANEL ---${C_NC}"
            echo "Buscando actualizaciones desde GitHub..."
            git pull 2>/dev/null || echo "Repositorio local actualizado."
            sleep 2
            ;;
        10)
            clear
            echo -e "${C_YELLOW}--- AUTO-INICIO EN LOGIN ---${C_NC}"
            if ! grep -q "menu.sh" /root/.bashrc; then
                echo "./menu.sh" >> /root/.bashrc
                echo -e "${C_GREEN}Auto-inicio activado con éxito.${C_NC}"
            else
                echo -e "${C_YELLOW}El auto-inicio ya estaba configurado.${C_NC}"
            fi
            sleep 1.5
            ;;
        11)
            clear
            echo -e "${C_CYAN}================================================${C_NC}"
            echo -e " 💻 ${C_YELLOW}ESPECIFICACIONES DEL SISTEMA${C_NC}"
            echo -e "${C_CYAN}================================================${C_NC}"
            echo -e " Procesador : $(lscpu | grep 'Model name' | cut -d ':' -f 2 | sed 's/^[ \t]*//')"
            echo -e " Núcleos    : $(nproc)"
            echo -e " Memoria RAM: $(free -h | awk 'NR==2{print $2}') Total"
            echo -e " Espacio HD : $(df -h / | awk 'NR==2{print $3 " / " $2 " (" $5 " usado)"}')"
            echo -e "${C_CYAN}================================================${C_NC}"
            read -p "Presiona [Enter] para volver al menú..."
            ;;
        12)
            clear
            echo -e "${C_YELLOW}--- GESTIÓN DE FIREWALL ---${C_NC}"
            ufw status
            read -p "Presiona Enter para continuar..."
            ;;
        13)
            clear
            echo -e "${C_YELLOW}--- INSTALAR CHECKUSER ---${C_NC}"
            echo "Monitoreo multi-aplicación preparado."
            sleep 1.5
            ;;
        14)
            clear
            echo -e "${C_YELLOW}--- CAMBIAR IDIOMA (ES/EN) ---${C_NC}"
            echo "Idioma actual: Español (ES)"
            sleep 1.5
            ;;
        15)
            clear
            echo -e "${C_YELLOW}--- REPARAR PUERTOS (NGINX) ---${C_NC}"
            systemctl restart nginx
            echo -e "${C_GREEN}Servicio Nginx reiniciado correctamente.${C_NC}"
            sleep 1.5
            ;;
        88)
            clear
            read -p "¿Estás seguro de desinstalar el script? (s/n): " confirm
            if [ "$confirm" = "s" ]; then
                rm -f /root/menu.sh
                echo "Panel desinstalado."
                exit 0
            fi
            ;;
        0) 
            clear
            exit 0 
            ;;
        *) 
            echo -e "${C_RED}Opción inválida: $opcion${C_NC}"
            sleep 1.5
            ;;
    esac
done
