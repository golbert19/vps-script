#!/bin/bash
# ==========================================
# Golbert VPS - Panel Principal V4.5 LTS
# ==========================================

# --- Colores ---
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# --- Variables y Rutas ---
DB_VMESS="/etc/vps-manager/vmess.json"
DB_VLESS="/etc/vps-manager/vless.json"
DB_TROJAN="/etc/vps-manager/trojan.json"

# ==========================================
# --- FUNCIONES DE MÓDULOS ---
# ==========================================
menu_ssh() { echo -e "\n${YELLOW}[!] Abriendo módulo SSH...${NC}"; sleep 1; }
menu_xray_proto() { echo -e "\n${YELLOW}[!] Abriendo módulo $1...${NC}"; sleep 1; }
menu_checkuser() { echo -e "\n${YELLOW}[!] Comprobando usuarios...${NC}"; sleep 1; }
menu_panel_vps() { echo -e "\n${YELLOW}[!] Abriendo configuración del VPS...${NC}"; sleep 1; }

# --- MÓDULO OPENVPN (WEB DE PERFILES .OVPN) ---
menu_openvpn() {
    clear
    echo -e "${CYAN}================================================${NC}"
    echo -e "${GREEN}             GESTIÓN DE OPENVPN                 ${NC}"
    echo -e "${CYAN}================================================${NC}"
    IP_ACTUAL=$(curl -s --max-time 3 ipv4.icanhazip.com || hostname -I | awk '{print $1}')
    echo -e "🔗 ${YELLOW}Enlace de descarga de perfiles (.ovpn):${NC}"
    echo -e "   ➡️  http://$IP_ACTUAL:2081"
    echo -e "${CYAN}================================================${NC}"
    echo -e "Los usuarios pueden acceder a este enlace para"
    echo -e "descargar sus archivos TCP, UDP, SSL y OHP."
    echo -e "${CYAN}================================================${NC}"
    read -p "Presione Enter para regresar al menú..."
}

# --- MÓDULO INSTALADOR PHP 8.5.12 ---
menu_install_php() {
    clear
    echo -e "${CYAN}================================================${NC}"
    echo -e "${GREEN}         INSTALADOR PHP 8.5.12 VPS              ${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo -e "${YELLOW}[+] Ejecutando instalador externo de PHP...${NC}\n"
    curl -sSL "https://raw.githubusercontent.com/golbert19/php-8.5.12-vps/main/install.sh?t=$(date +%s)" | sed '59s/[()]//g' | bash
    echo -e "\n${CYAN}================================================${NC}"
    echo -e "${GREEN}[✔] Proceso de PHP finalizado.${NC}"
    echo -e "${CYAN}================================================${NC}"
    read -p "Presione Enter para regresar al menú..."
}

# --- MÓDULO BBR (Acelerador de Red) ---
menu_bbr() {
    clear
    echo -e "${CYAN}================================================${NC}"
    echo -e "${GREEN}           INSTALADOR / ACTIVADOR BBR           ${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo -e "${YELLOW}[+] Descargando y aplicando Bbr.sh...${NC}\n"
    
    if [ -f /etc/vps-manager/core/Bbr.sh ]; then
        bash /etc/vps-manager/core/Bbr.sh
    else
        wget -qO /tmp/Bbr.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/Bbr.sh && chmod +x /tmp/Bbr.sh && bash /tmp/Bbr.sh
    fi
    
    echo -e "\n${CYAN}================================================${NC}"
    read -p "Presione Enter para regresar al menú..."
}

# --- MÓDULO SSHWS ---
menu_sshws() {
    clear
    echo -e "${CYAN}================================================${NC}"
    echo -e "${GREEN}             INSTALADOR SSHWS                   ${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo -e "${YELLOW}[+] Configurando SSHWS...${NC}\n"
    
    if [ -f /etc/vps-manager/core/sshws.sh ]; then
        bash /etc/vps-manager/core/sshws.sh
    else
        wget -qO /tmp/sshws.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/sshws.sh && chmod +x /tmp/sshws.sh && bash /tmp/sshws.sh
    fi
    
    echo -e "\n${CYAN}================================================${NC}"
    read -p "Presione Enter para regresar al menú..."
}

# --- MÓDULO WEBSOCKET ---
menu_websocket() {
    clear
    echo -e "${CYAN}================================================${NC}"
    echo -e "${GREEN}            INSTALADOR WEBSOCKET                ${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo -e "${YELLOW}[+] Configurando Websocket...${NC}\n"
    
    if [ -f /etc/vps-manager/core/websocket.sh ]; then
        bash /etc/vps-manager/core/websocket.sh
    else
        wget -qO /tmp/websocket.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/websocket.sh && chmod +x /tmp/websocket.sh && bash /tmp/websocket.sh
    fi
    
    echo -e "\n${CYAN}================================================${NC}"
    read -p "Presione Enter para regresar al menú..."
}

# --- FUNCIÓN DE DESINSTALACIÓN ---
uninstall_script() {
    echo -e "\n${RED}⚠️ ¿Estás seguro que deseas desinstalar Golbert VPS por completo? (s/n): ${NC}"
    read -r confirmar
    if [[ "$confirmar" == "s" || "$confirmar" == "S" ]]; then
        echo -e "\n${YELLOW}[!] Eliminando archivos y configuraciones...${NC}"
        sleep 1
        rm -rf /etc/vps-manager
        rm -f /usr/local/bin/menu
        echo -e "${GREEN}[✔] Script desinstalado correctamente. ¡Hasta pronto!${NC}"
        sleep 2
        clear
        exit 0
    else
        echo -e "${GREEN}[+] Desinstalación cancelada.${NC}"
        sleep 1
    fi
}

# ==========================================
# --- BUCLE PRINCIPAL DEL MENÚ ---
# ==========================================
while true; do
    clear
    # --- Captura de información del VPS en tiempo real ---
    OS=$(cat /etc/os-release | grep -w PRETTY_NAME | head -n 1 | cut -d "=" -f 2 | sed 's/"//g')
    IP=$(curl -s --max-time 3 ipv4.icanhazip.com || hostname -I | awk '{print $1}')
    RAM=$(free -m | awk 'NR==2{printf "%s / %s MB", $3,$2}')
    CPU=$(top -bn1 | grep load | awk '{printf "%.2f", $(NF-2)}')
    UPTIME=$(uptime -p | sed 's/up //')

    # --- Diseño del Menú ---
    echo -e "${CYAN}================================================${NC}"
    echo -e "${GREEN}          PANEL PRINCIPAL GOLBERT VPS           ${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo -e "${YELLOW} Sistema OS : ${NC}$OS"
    echo -e "${YELLOW} IP Pública : ${NC}$IP"
    echo -e "${YELLOW} Memoria RAM: ${NC}$RAM"
    echo -e "${YELLOW} Carga CPU  : ${NC}$CPU"
    echo -e "${YELLOW} Tiempo Activo: ${NC}$UPTIME"
    echo -e "${CYAN}================================================${NC}"
    echo -e "${GREEN}1) ${NC}Menú SSH / Dropbear"
    echo -e "${GREEN}2) ${NC}Menú Xray (VMess)"
    echo -e "${GREEN}3) ${NC}Menú Xray (VLESS)"
    echo -e "${GREEN}4) ${NC}Menú Xray (Trojan)"
    echo -e "${GREEN}5) ${NC}Comprobar Usuarios"
    echo -e "${GREEN}6) ${NC}Menú OpenVPN (Web Perfiles)"
    echo -e "${GREEN}7) ${NC}Instalador PHP 8.5.12"
    echo -e "${GREEN}8) ${NC}Acelerador BBR"
    echo -e "${GREEN}10)${NC}Instalar SSHWS"
    echo -e "${GREEN}11)${NC}Instalar Websocket"
    echo -e "${GREEN}9) ${NC}Panel General VPS"
    echo -e "${CYAN}================================================${NC}"
    echo -e "${RED}88) Desinstalar Script${NC}"
    echo -e "${RED}0) Salir del Panel${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo -n -e "${YELLOW}Seleccione una opción: ${NC}"
    read opcion

    case $opcion in
        1|01) menu_ssh ;;
        2|02) menu_xray_proto "vmess" "$DB_VMESS" ;;
        3|03) menu_xray_proto "vless" "$DB_VLESS" ;;
        4|04) menu_xray_proto "trojan" "$DB_TROJAN" ;;
        5|05) menu_checkuser ;;
        6|06) menu_openvpn ;;
        7|07) menu_install_php ;;
        8|08) menu_bbr ;;
        10) menu_sshws ;;
        11) menu_websocket ;;
        9|09) menu_panel_vps ;;
        88) uninstall_script ;;
        x|X|0) 
            clear
            echo -e "${GREEN}Saliendo del Panel... ¡Hasta luego!${NC}"
            exit 0 
            ;;
        *) 
            echo -e "\n${RED}[!] Opción inválida. Por favor intente de nuevo.${NC}"
            sleep 1 
            ;;
    esac
done
