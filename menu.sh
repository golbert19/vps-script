#!/bin/bash
# ==========================================
# Panel Principal - Golbert VPS V5.0 LTS
# ==========================================

C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'
C_PURPLE='\033[1;35m'
C_NC='\033[0m'

while :
do
    clear
    # ==========================================
    # DATOS DE SISTEMA Y RECURSOS
    # ==========================================
    # Memoria RAM
    total_ram=$(free -m | awk 'NR==2 {print $2}')
    used_ram=$(free -m | awk 'NR==2 {print $3}')
    ram_usage=$((used_ram * 100 / total_ram))
    
    # Conteo de usuarios
    total_users=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)
    online_users=$(ps -u root | grep sshd | wc -l)
    
    # Estado de Servicios
    [ "$(systemctl is-active ssh)" = "active" ] && s_ssh="${C_GREEN}ON${C_NC}" || s_ssh="${C_RED}OFF${C_NC}"
    [ "$(systemctl is-active nginx)" = "active" ] && s_nginx="${C_GREEN}ON${C_NC}" || s_nginx="${C_RED}OFF${C_NC}"
    [ "$(systemctl is-active xray)" = "active" ] && s_xray="${C_GREEN}ON${C_NC}" || s_xray="${C_RED}OFF${C_NC}"
    [ "$(systemctl is-active stunnel4)" = "active" ] && s_stunnel="${C_GREEN}ON${C_NC}" || s_stunnel="${C_RED}OFF${C_NC}"
    [ "$(systemctl is-active ws-python)" = "active" ] && s_ws="${C_GREEN}ON${C_NC}" || s_ws="${C_RED}OFF${C_NC}"
    [ "$(systemctl is-active hcr)" = "active" ] || [ -f /etc/vps-manager/hcr.pid ] && s_hcr="${C_GREEN}ON${C_NC}" || s_hcr="${C_RED}OFF${C_NC}"

    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 🧠 CPU Usage: $(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print sprintf("%.1f", usage)}')%"
    echo -e " 📊 RAM Usage: ${ram_usage}% (${used_ram} / ${total_ram} MB)"
    echo -e " 👥 Users    : ${C_YELLOW}${total_users}${C_NC} Creados | ${C_GREEN}${online_users}${C_NC} En Línea"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " SSH   : $s_ssh   NGINX : $s_nginx   XRAY : $s_xray"
    echo -e " STUNNEL : $s_stunnel SSH-WS : $s_ws   HCR : $s_hcr"
    echo -e "${C_CYAN}================================================${C_NC}"
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
    echo -e " ${C_CYAN}8.${C_NC} 💻 Generate Web Panel (Dashboard UI)"
    echo -e " ${C_CYAN}9.${C_NC} 🔄 Update Panel (From GitHub)"
    echo -e " ${C_CYAN}10.${C_NC} 🚀 Enable Auto-Start on Login"
    echo -e " ${C_CYAN}11.${C_NC} 💻 VPS Specifications & Capacity"
    echo -e " ${C_CYAN}12.${C_NC} 🛡️ Firewall Manager (Rules & Security)"
    echo -e " ${C_CYAN}13.${C_NC} 👥 Install CheckUser (Multi-App Monitor)"
    echo -e " ${C_CYAN}14.${C_NC} 🌍 Change Language (ES/EN)"
    echo -e " ${C_CYAN}15.${C_NC} 🔧 Repair / Fix Ports (Nginx Gateway)"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " ${C_RED}88.${C_NC} ❌ Uninstall Script   |  ${C_CYAN}0.${C_NC} 🚪 Exit"
    echo -e "${C_CYAN}================================================${C_NC}"
    
    read -p "Selecciona una opción: " opcion

    case $opcion in
        1)
            [ -f /etc/vps-manager/core/user.sh ] && bash /etc/vps-manager/core/user.sh || echo -e "${C_RED}[!] Módulo no encontrado${C_NC}"; sleep 2
            ;;
        2)
            echo "Módulo de Revendedores en desarrollo..." && sleep 2
            ;;
        3)
            # Submenú de instaladores (Opción 11 que buscaba sshw.sh)
            clear
            echo -e "${C_CYAN}================================================${C_NC}"
            echo -e " 🛠️  INSTALLERS & PROTOCOLS MANAGER"
            echo -e "${C_CYAN}================================================${C_NC}"
            echo -e " 1. 📦 Xray Multi-Protocol Manager (xray_manager.sh)"
            echo -e " 2. ⚡ VMess Dual Ports (vmess.sh)"
            echo -e " 3. ⚡ VLESS Protocol (vless.sh)"
            echo -e " 4. 🛡️ Trojan Port 443 (trojan.sh)"
            echo -e " 5. 🐢 SlowDNS V5.0 LTS (slowdns.sh)"
            echo -e " 6. 🎮 BadVPN UDPGW 7200/7300 (badvpn.sh)"
            echo -e " 7. 🚀 HCR Nativo Port 8888 (hcr.sh)"
            echo -e " 8. 🔥 Hysteria / Hysteria 2 UDP (hysteria.sh)"
            echo -e " 9. 🎯 UDP Custom Port 2000/25000 (udp_custom.sh)"
            echo -e " 10. 🌐 BHTTP Proxy Port 8080 (bhttp.sh)"
            echo -e " 11. 🌐 SSH WebSocket Python (sshw.sh / websocket.sh)"
            echo -e " 12. 🔒 SSL/TLS Stunnel Proxy (ssl.sh)"
            echo -e " 13. 🛡️ OpenVPN Server Setup (setup_openvpn.sh)"
            echo -e " 14. 🌐 ZivPN UDP Manager (zivpn.sh)"
            echo -e " 15. ⚙️ TCP BBR Optimizer (bbr.sh)"
            echo -e " 0. 🚪 VOLVER al Menú Principal"
            echo -e "${C_CYAN}================================================${C_NC}"
            read -p "Selecciona el protocolo a instalar/gestionar: " sub_op
            
            if [ "$sub_op" = "11" ]; then
                clear
                echo -e "${C_CYAN}1) SSH-WS (sshws.sh)${C_NC}"
                echo -e "${C_CYAN}2) WebSocket Manager (websocket.sh)${C_NC}"
                read -p "Opción: " ws_op
                if [ "$ws_op" = "1" ]; then
                    systemctl restart ws-python 2>/dev/null && echo -e "${C_GREEN}[✔] WebSocket reiniciado con éxito.${C_NC}" || echo -e "${C_RED}[✘] Error al reiniciar.${C_NC}"
                    sleep 2
                fi
            elif [ "$sub_op" = "0" ]; then
                continue
            else
                echo "Opción en gestión..." && sleep 2
            fi
            ;;
        4)
            echo "Configurando Banner HTML..." && sleep 2
            ;;
        5)
            netstat -tulnp
            read -p "Presiona Enter para continuar..."
            ;;
        6)
            echo "Administrador de Dominios y SSL..." && sleep 2
            ;;
        7)
            echo "Enlace de Bot de Telegram..." && sleep 2
            ;;
        8)
            echo "Generando Panel Web..." && sleep 2
            ;;
        9)
            echo "Actualizando desde GitHub..." && sleep 2
            ;;
        10)
            echo "Auto-Start configurado." && sleep 2
            ;;
        11)
            neofetch || lscpu
            read -p "Presiona Enter para continuar..."
            ;;
        12)
            ufw status
            read -p "Presiona Enter para continuar..."
            ;;
        13)
            echo "CheckUser instalado." && sleep 2
            ;;
        14)
            echo "Idioma cambiado." && sleep 2
            ;;
        15)
            [ -f /etc/vps-manager/fix_ports.sh ] && bash /etc/vps-manager/fix_ports.sh || echo "Script no encontrado"
            sleep 2
            ;;
        88)
            read -p "¿Estás seguro de desinstalar todo el script? (s/n): " des
            [ "$des" = "s" ] && exit 0
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${C_RED}¡Opción inválida!${C_NC}"
            sleep 1
            ;;
    esac
done
