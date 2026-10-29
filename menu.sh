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

# Cargar traducciones de idioma
[ -f /etc/vps-manager/languages.sh ] && source /etc/vps-manager/languages.sh || {
    LANG_FILE="/etc/vps-manager/lang.txt"
    [ -f "$LANG_FILE" ] && current_lang=$(cat "$LANG_FILE") || current_lang="es"
    if [ "$current_lang" = "en" ]; then
        t_mgmt="[ ACCOUNT MANAGEMENT ]"; t_tools="[ TOOLS & SYSTEM ]"; t_select="Select an option: "
    elif [ "$current_lang" = "pt" ]; then
        t_mgmt="[ GERENCIAMENTO DE CONTAS ]"; t_tools="[ FERRAMENTAS & SISTEMA ]"; t_select="Selecione uma opção: "
    else
        t_mgmt="[ GESTIÓN DE CUENTAS ]"; t_tools="[ HERRAMIENTAS Y SISTEMA ]"; t_select="Selecciona una opción: "
    fi
}

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

os_name=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
kernel_ver=$(uname -r)
IP=$(curl -sS ifconfig.me 2>/dev/null || wget -qO- ipv4.icanhazip.com)
domain_name="No configurado"
[ -f /etc/vps-manager/domain.txt ] && domain_name=$(cat /etc/vps-manager/domain.txt)

while true; do
    clear
    total_ram=$(free -m | awk 'NR==2 {print $2}')
    used_ram=$(free -m | awk 'NR==2 {print $3}')
    ram_usage=$((used_ram * 100 / total_ram))
    ram_bar=$(draw_bar $ram_usage)

    cpu_usage_raw=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')
    cpu_usage=$(printf "%.2f" "$cpu_usage_raw")
    cpu_usage_int=${cpu_usage_raw%.*}
    cpu_bar=$(draw_bar $cpu_usage_int)

    total_users=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)
    online_users=$(ps -u root | grep sshd | wc -l)

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
    echo -e "${C_YELLOW}$t_mgmt${C_NC}"
    echo -e " ${C_CYAN}1.${C_NC} 👤 SSH Management (Users, Limit, HWID)"
    echo -e " ${C_CYAN}2.${C_NC} 🤝 Reseller Management (Credits)"
    echo -e ""
    echo -e "${C_YELLOW}$t_tools${C_NC}"
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
    echo -e " ${C_CYAN}14.${C_NC} 🌍 Change Language (ES/EN/PT)"
    echo -e " ${C_CYAN}15.${C_NC} 🔧 Repair / Fix Ports (Nginx Gateway)"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " ${C_RED}88. ❌ Uninstall Script   |   0. 🚪 Exit${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " ${C_CYAN}Soporte Telegram : @golbert_service${C_NC}"
    echo -e " ${C_CYAN}WhatsApp Oficial : +51960084993${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    
    read -p " $t_select" opcion
    
    case $opcion in
        1) [ -f /etc/vps-manager/core/user.sh ] && bash /etc/vps-manager/core/user.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        2) [ -f /etc/vps-manager/core/bot.sh ] && bash /etc/vps-manager/core/bot.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        3)
            while true; do
                clear
                echo -e "${C_CYAN}================================================${C_NC}"
                echo -e " 🛠️  INSTALLERS & PROTOCOLS MANAGER"
                echo -e "${C_CYAN}================================================${C_NC}"
                echo -e " 1. 📦 Xray Multi-Protocol Manager"
                echo -e " 2. ⚡ VMess Dual Ports"
                echo -e " 3. ⚡ VLESS Protocol"
                echo -e " 4. 🛡️ Trojan Port 443"
                echo -e " 5. 🐢 SlowDNS V5.0 LTS"
                echo -e " 6. 🎮 BadVPN UDPGW 7200/7300"
                echo -e " 7. 🚀 HCR Nativo Port 8888"
                echo -e " 8. 🔥 Hysteria / Hysteria 2 UDP"
                echo -e " 9. 🎯 UDP Custom Port 2000/25000"
                echo -e " 10. 🌐 BHTTP Proxy Port 8080"
                echo -e " 11. 🌐 SSH WebSocket Python"
                echo -e " 12. 🔒 SSL/TLS Stunnel Proxy"
                echo -e " 13. 🛡️ OpenVPN Server Setup"
                echo -e " 14. 🌐 ZivPN UDP Manager"
                echo -e " 15. ⚙️ TCP BBR Optimizer"
                echo -e " 0. 🚪 VOLVER al Menú Principal"
                echo -e "${C_CYAN}================================================${C_NC}"
                read -p "Selecciona el protocolo a instalar/gestionar: " sub_op

                case $sub_op in
                    1) [ -f /etc/vps-manager/core/xray_manager.sh ] && bash /etc/vps-manager/core/xray_manager.sh || echo "Módulo no encontrado" ; sleep 2 ;;
                    2) [ -f /etc/vps-manager/core/vmess.sh ] && bash /etc/vps-manager/core/vmess.sh || echo "Módulo no encontrado" ; sleep 2 ;;
                    3) [ -f /etc/vps-manager/core/vless.sh ] && bash /etc/vps-manager/core/vless.sh || echo "Módulo no encontrado" ; sleep 2 ;;
                    4) [ -f /etc/vps-manager/core/trojan.sh ] && bash /etc/vps-manager/core/trojan.sh || echo "Módulo no encontrado" ; sleep 2 ;;
                    5) [ -f /etc/vps-manager/core/slowdns.sh ] && bash /etc/vps-manager/core/slowdns.sh || echo "Módulo no encontrado" ; sleep 2 ;;
                    6) [ -f /etc/vps-manager/core/badvpn.sh ] && bash /etc/vps-manager/core/badvpn.sh || echo "Módulo no encontrado" ; sleep 2 ;;
                    7) [ -f /etc/vps-manager/core/hcr.sh ] && bash /etc/vps-manager/core/hcr.sh || echo "Módulo no encontrado" ; sleep 2 ;;
                    8) [ -f /etc/vps-manager/core/hysteria.sh ] && bash /etc/vps-manager/core/hysteria.sh || echo "Módulo no encontrado" ; sleep 2 ;;
                    9) [ -f /etc/vps-manager/core/udp_custom.sh ] && bash /etc/vps-manager/core/udp_custom.sh || echo "Módulo no encontrado" ; sleep 2 ;;
                    10) [ -f /etc/vps-manager/core/bhttp.sh ] && bash /etc/vps-manager/core/bhttp.sh || echo "Módulo no encontrado" ; sleep 2 ;;
                    11) [ -f /etc/vps-manager/core/sshws.sh ] && bash /etc/vps-manager/core/sshws.sh || echo "Módulo no encontrado" ; sleep 2 ;;
                    12) [ -f /etc/vps-manager/core/ssl.sh ] && bash /etc/vps-manager/core/ssl.sh || echo "Módulo no encontrado" ; sleep 2 ;;
                    13) [ -f /etc/vps-manager/core/setup_openvpn.sh ] && bash /etc/vps-manager/core/setup_openvpn.sh || echo "Módulo no encontrado" ; sleep 2 ;;
                    14) [ -f /etc/vps-manager/core/zivpn.sh ] && bash /etc/vps-manager/core/zivpn.sh || echo "Módulo no encontrado" ; sleep 2 ;;
                    15) [ -f /etc/vps-manager/core/bbr.sh ] && bash /etc/vps-manager/core/bbr.sh || echo "Módulo no encontrado" ; sleep 2 ;;
                    0) break ;;
                    *) echo -e "${C_RED}Opción inválida.${C_NC}" ; sleep 1 ;;
                esac
            done
            ;;
        4) [ -f /etc/vps-manager/core/banner.sh ] && bash /etc/vps-manager/core/banner.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        5) netstat -tulnp | grep -E 'ssh|nginx|xray|stunnel|python|hcr' ; read -p "Presiona Enter para continuar..." ;;
        6) [ -f /etc/vps-manager/core/domain.sh ] && bash /etc/vps-manager/core/domain.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        7) [ -f /etc/vps-manager/core/bot.sh ] && bash /etc/vps-manager/core/bot.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        8) [ -f /etc/vps-manager/core/webpanel.sh ] && bash /etc/vps-manager/core/webpanel.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        9) [ -f /etc/vps-manager/core/update.sh ] && bash /etc/vps-manager/core/update.sh || { [ -f /etc/vps-manager/update.sh ] && bash /etc/vps-manager/update.sh; } || echo "Módulo no encontrado" ; sleep 2 ;;
        10) echo "Auto-Start configurado." ; sleep 2 ;;
        11) [ -f /etc/vps-manager/core/specs.sh ] && bash /etc/vps-manager/core/specs.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        12) [ -f /etc/vps-manager/core/firewall.sh ] && bash /etc/vps-manager/core/firewall.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        13) [ -f /etc/vps-manager/core/checkuser.sh ] && bash /etc/vps-manager/core/checkuser.sh || echo "Módulo no encontrado" ; sleep 2 ;;
        14)
            while true; do
                clear
                echo -e "${C_CYAN}================================================${C_NC}"
                echo -e " 🌍 CHANGE LANGUAGE / CAMBIAR IDIOMA / IDIOMA"
                echo -e "${C_CYAN}================================================${C_NC}"
                echo -e " 1. 🇪🇸 Español"
                echo -e " 2. 🇺🇸 English"
                echo -e " 3. 🇧🇷 Português"
                echo -e " 0. 🚪 Volver al Menú"
                echo -e "${C_CYAN}================================================${C_NC}"
                read -p "Selecciona una opción / Select option: " lang_op
                
                case $lang_op in
                    1)
                        echo "es" > /etc/vps-manager/lang.txt
                        echo -e "\n${C_GREEN}[✔] Idioma cambiado a Español.${C_NC}"
                        sleep 1.5
                        break
                        ;;
                    2)
                        echo "en" > /etc/vps-manager/lang.txt
                        echo -e "\n${C_GREEN}[✔] Language changed to English.${C_NC}"
                        sleep 1.5
                        break
                        ;;
                    3)
                        echo "pt" > /etc/vps-manager/lang.txt
                        echo -e "\n${C_GREEN}[✔] Idioma alterado para Português.${C_NC}"
                        sleep 1.5
                        break
                        ;;
                    0) break ;;
                    *) echo -e "${C_RED}Opción inválida / Invalid option.${C_NC}"; sleep 1 ;;
                esac
            done
            ;;
        15) [ -f /etc/vps-manager/core/fix_ports.sh ] && bash /etc/vps-manager/core/fix_ports.sh || echo "Script no encontrado" ; sleep 2 ;;
        88) read -p "¿Desinstalar script? (s/n): " des; [ "$des" = "s" ] && exit 0 ;;
        0) clear ; exit 0 ;;
        *) echo -e "${C_RED}Opción inválida.${C_NC}" ; sleep 1 ;;
    esac
done
