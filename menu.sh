#!/bin/bash
# ==========================================
# Golbert VPS - Panel Principal V4.5 LTS
# ==========================================

RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'
mkdir -p /etc/vps-manager

# ==========================================
# 1. GESTOR SSH (Con Subdominios y SlowDNS Key)
# ==========================================
menu_ssh() {
    while true; do
        clear; echo -e "${CYAN}================================================${NC}"; echo -e "${GREEN}             GESTOR DE SSH / DROPBEAR           ${NC}"; echo -e "${CYAN}================================================${NC}"
        echo -e "${GREEN}1) ${NC}Crear nuevo usuario SSH\n${GREEN}2) ${NC}Eliminar usuario SSH\n${GREEN}3) ${NC}Renovar usuario SSH\n${GREEN}4) ${NC}Lista de conectados\n${GREEN}0) ${NC}Volver"
        echo -e "${CYAN}================================================${NC}"; read -p "Seleccione una opción: " opt
        case $opt in
            1) 
                read -p "Usuario: " user; read -p "Contraseña: " pass; read -p "Días: " dias
                useradd -e $(date -d "+$dias days" +"%Y-%m-%d") -s /bin/false -M $user; echo "$user:$pass" | chpasswd
                
                # Obtener datos adicionales
                IP_V=$(curl -s ipv4.icanhazip.com)
                DOM=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "$IP_V" )
                NS_DOM=$( [ -f /etc/vps-manager/nsdomain ] && cat /etc/vps-manager/nsdomain || echo "No configurado" )
                PUB_KEY=$( [ -f /etc/vps-manager/slowdns/server.pub ] && cat /etc/vps-manager/slowdns/server.pub || echo "No instalada" )
                EXP=$(date -d "+$dias days" +"%d/%m/%Y")
                
                clear; echo -e "${CYAN}================================================${NC}"
                echo -e "${GREEN}        ✅ CUENTA CREADA EXITOSAMENTE ✅        ${NC}"
                echo -e "${CYAN}================================================${NC}"
                echo -e " 👤 Usuario       : $user"
                echo -e " 🔑 Clave         : $pass"
                echo -e " 📅 Vence         : $EXP ($dias días)\n"
                echo -e " 🌐 Host/IP       : $DOM"
                echo -e " 🌐 Subdominio NS : $NS_DOM"
                echo -e " 🔐 Pub Key (DNS) : $PUB_KEY"
                echo -e " 🎯 Puertos       : 22(SSH), 80(WS), 443(SSL), 53(DNS)"
                echo -e "${CYAN}================================================${NC}"
                read -p "Copia los datos y presiona Enter..." ;;
            2) read -p "Usuario a eliminar: " user; userdel -f $user 2>/dev/null; echo -e "${GREEN}[✔] Eliminado.${NC}"; sleep 2 ;;
            3) read -p "Usuario a renovar: " user; read -p "Nuevos días: " dias; chage -E $(date -d "+$dias days" +"%Y-%m-%d") $user; echo -e "${GREEN}[✔] Renovado.${NC}"; sleep 2 ;;
            4) echo -e "${YELLOW}Conectados:${NC}"; ps -ef | grep -E "sshd|dropbear" | grep -v root | grep -v grep | awk '{print $1}' | sort | uniq -c; read -p "Enter..." ;;
            0) break ;;
            *) echo -e "${RED}[!] Inválido.${NC}"; sleep 1 ;;
        esac
    done
}

# ==========================================
# 2,3,4. GESTOR XRAY (Descarga archivo maestro)
# ==========================================
menu_xray_proto() {
    PROTO=$1
    clear
    echo -e "${YELLOW}[+] Iniciando Módulo de $PROTO...${NC}"
    wget -qO /tmp/xray_manager.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/xray_manager.sh
    chmod +x /tmp/xray_manager.sh
    bash /tmp/xray_manager.sh "$PROTO"
}

# ==========================================
# 5. COMPROBAR USUARIOS
# ==========================================
menu_checkuser() {
    clear; echo -e "${CYAN}================================================${NC}"; echo -e "${GREEN}             MONITOR DE USUARIOS                ${NC}"; echo -e "${CYAN}================================================${NC}"
    echo -e "${YELLOW}Total de cuentas SSH:${NC} $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)"
    echo -e "\n${YELLOW}Usuarios expirados:${NC}"
    for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
        exp_date=$(chage -l $user | grep "Account expires" | awk -F": " '{print $2}')
        if [[ "$exp_date" != "never" ]]; then
            if [ $(date +%s) -ge $(date -d "$exp_date" +%s 2>/dev/null || echo 9999999999) ]; then echo -e "${RED}- $user (Expiró el $exp_date)${NC}"; fi
        fi
    done
    echo -e "${CYAN}================================================${NC}"; read -p "Enter para continuar..."
}

# ==========================================
# 6. OPENVPN (Instalador Real)
# ==========================================
menu_openvpn() {
    clear
    echo -e "${YELLOW}[+] Verificando e instalando OpenVPN Completo...${NC}"
    
    # Descarga y ejecuta el instalador real de OpenVPN
    wget -qO /tmp/setup_openvpn.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/setup_openvpn.sh && chmod +x /tmp/setup_openvpn.sh && bash /tmp/setup_openvpn.sh
    
    # Asegurar que el puerto de descarga web esté abierto en el Firewall
    iptables -I INPUT -p tcp --dport 2081 -j ACCEPT
    iptables-save > /etc/iptables.up.rules 2>/dev/null
    
    IP_ACTUAL=$(curl -s --max-time 3 ipv4.icanhazip.com || hostname -I | awk '{print $1}')
    DOM=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "$IP_ACTUAL" )
    
    echo -e "\n${GREEN}[✔] ¡Servidor Web Operativo!${NC}"
    echo -e "🔗 ${YELLOW}Tus clientes pueden descargar perfiles (.ovpn) aquí:${NC} http://$DOM:2081\n"
    read -p "Presione Enter para continuar..."
}

# ==========================================
# 14. BANNER SSH (Forzado a /etc/issue.net)
# ==========================================
menu_banner() {
    clear; echo -e "${CYAN}================================================${NC}"; echo -e "${GREEN}             GESTOR DE BANNER SSH               ${NC}"; echo -e "${CYAN}================================================${NC}"
    echo -e "${YELLOW}1) ${NC}Banner por Defecto\n${YELLOW}2) ${NC}Banner Personalizado HTML\n${CYAN}================================================${NC}"; read -p "Opción: " opt_ban
    case $opt_ban in
        1) TEXTO="<br><font color='cyan'><b>🌟 BIENVENIDO A GOLBERT VPS 🌟</b></font><br><font color='green'>Conexión Segura y Estable</font><br><font color='yellow'>Prohibido DDOS / Spam / Torrent</font><br>" ;;
        2) echo -e "Escribe tu mensaje HTML: "; read TEXTO ;;
        *) TEXTO="Bienvenido al servidor" ;;
    esac
    
    echo "$TEXTO" > /etc/issue.net
    sed -i '/^Banner/d' /etc/ssh/sshd_config
    echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
    systemctl restart sshd
    
    if [ -f /etc/default/dropbear ]; then
        sed -i 's/DROPBEAR_BANNER=""/DROPBEAR_BANNER="\/etc\/issue.net"/g' /etc/default/dropbear
        systemctl restart dropbear
    fi

    cat << 'EOF' > /etc/profile.d/vps_saludo.sh
#!/bin/bash
if [ -n "$SSH_CLIENT" ]; then
    USER=$(whoami)
    if [ "$USER" != "root" ]; then
        EXP=$(chage -l $USER | grep "Account expires" | awk -F": " '{print $2}')
        echo -e "\033[1;36m========================================\033[0m"
        echo -e "\033[1;32m 👤 BIENVENIDO: \033[1;37m$USER\033[0m"
        if [[ "$EXP" != "never" ]]; then echo -e "\033[1;33m ⏳ TU CUENTA EXPIRA: \033[1;37m$EXP\033[0m"
        else echo -e "\033[1;33m ⏳ TU CUENTA ES: \033[1;37mILIMITADA\033[0m"; fi
        echo -e "\033[1;36m========================================\033[0m\n"
    fi
fi
EOF
    chmod +x /etc/profile.d/vps_saludo.sh
    echo -e "${GREEN}[✔] Banner SSH y Mensaje aplicados correctamente.${NC}"; read -p "Presione Enter..."
}

# ==========================================
# 12. SLOWDNS
# ==========================================
menu_slowdns() { 
    clear; echo -e "${YELLOW}[+] Instalando SlowDNS...${NC}"
    echo -e "\033[1;33mPara SlowDNS, necesitas un subdominio NS (Ej: ns1.golbertvps.online)\033[0m"
    read -p "Ingresa tu Dominio NS: " NS_DOMAIN
    echo "$NS_DOMAIN" > /etc/vps-manager/nsdomain
    wget -qO /tmp/Slowdns.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/Slowdns.sh && chmod +x /tmp/Slowdns.sh && bash /tmp/Slowdns.sh
    read -p "Enter..." 
}

# ==========================================
# OTROS MÓDULOS (Optimizar, Actualizar, Autoinicio)
# ==========================================
menu_optimizar() {
    clear; echo -e "${CYAN}================================================${NC}"; echo -e "${YELLOW}[+] Limpiando caché y optimizando RAM...${NC}"
    sync; echo 3 > /proc/sys/vm/drop_caches; sysctl -w vm.drop_caches=3 > /dev/null 2>&1; apt clean -y; apt autoclean -y > /dev/null 2>&1
    echo -e "${GREEN}[✔] Servidor optimizado exitosamente.${NC}"; read -p "Presione Enter..."
}

menu_update() {
    clear; echo -e "${YELLOW}[+] Buscando actualizaciones en GitHub...${NC}"
    wget -qO /tmp/menu.sh "https://raw.githubusercontent.com/golbert19/vps-script/main/menu.sh"
    if [ -s /tmp/menu.sh ]; then mv /tmp/menu.sh /usr/local/bin/menu; chmod +x /usr/local/bin/menu; echo -e "${GREEN}[✔] ¡Script actualizado!${NC}"; sleep 2; exec menu; else echo -e "${RED}[!] Error al actualizar.${NC}"; sleep 2; fi
}

menu_autostart() {
    clear; echo -e "${YELLOW}[+] Configurando inicio automático...${NC}"
    if grep -q "menu" /root/.bashrc; then echo -e "${GREEN}[✔] YA ESTÁ configurado.${NC}"; else echo -e "\nmenu" >> /root/.bashrc; echo -e "${GREEN}[✔] ¡Listo! El menú se abrirá al loguearte.${NC}"; fi; read -p "Enter..."
}

# ==========================================
# 9. PANEL GENERAL VPS (Info y Dominio)
# ==========================================
menu_panel_vps() {
    while true; do
        clear; echo -e "${CYAN}================================================${NC}"; echo -e "${GREEN}            PANEL GENERAL DEL SERVIDOR          ${NC}"; echo -e "${CYAN}================================================${NC}"
        echo -e "${YELLOW}1) ${NC}Ver Info VPS\n${YELLOW}2) ${NC}Configurar Subdominio VPS\n${YELLOW}0) ${NC}Volver"
        echo -e "${CYAN}================================================${NC}"; read -p "Opción: " opt
        case $opt in
            1) clear; echo -e "${CYAN}================================================${NC}\n${YELLOW}OS:${NC} $(cat /etc/os-release | grep -w PRETTY_NAME | cut -d= -f2 | tr -d '\"')\n${YELLOW}IP:${NC} $(curl -s ipv4.icanhazip.com)\n${YELLOW}RAM:${NC} $(free -m | awk 'NR==2{printf "%s / %s MB", $3,$2}')\n${CYAN}================================================${NC}"; read -p "Enter..." ;;
            2) echo -e "\n${YELLOW}Ingrese el subdominio VPS (Ej: centrix.golbertvps.online)${NC}"; read -p "Subdominio: " ndom; echo "$ndom" > /etc/vps-manager/dominio; echo -e "${GREEN}[✔] Guardado.${NC}"; sleep 2 ;;
            0) break ;;
        esac
    done
}

# ==========================================
# INSTALADORES DIRECTOS (PHP, BBR, SSHWS, WEBSOCKET)
# ==========================================
menu_install_php() { clear; curl -sSL "https://raw.githubusercontent.com/golbert19/php-8.5.12-vps/main/install.sh?t=$(date +%s)" | sed '59s/[()]//g' | bash; read -p "Enter..." ; }
menu_bbr() { clear; wget -qO /tmp/Bbr.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/Bbr.sh && chmod +x /tmp/Bbr.sh && bash /tmp/Bbr.sh; read -p "Enter..." ; }
menu_sshws() { clear; wget -qO /tmp/sshws.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/sshws.sh && chmod +x /tmp/sshws.sh && bash /tmp/sshws.sh; read -p "Enter..." ; }
menu_websocket() { clear; wget -qO /tmp/websocket.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/websocket.sh && chmod +x /tmp/websocket.sh && bash /tmp/websocket.sh; read -p "Enter..." ; }

uninstall_script() { echo -e "\n${RED}⚠️ ¿Desinstalar Golbert VPS? (s/n): ${NC}"; read -r conf; if [[ "$conf" == "s" || "$conf" == "S" ]]; then rm -rf /etc/vps-manager; rm -f /usr/local/bin/menu; echo -e "${GREEN}[✔] Script desinstalado.${NC}"; sleep 2; clear; exit 0; fi; }

# ==========================================
# BUCLE PRINCIPAL
# ==========================================
while true; do
    clear
    OS=$(cat /etc/os-release | grep -w PRETTY_NAME | head -n 1 | cut -d "=" -f 2 | sed 's/"//g')
    IP=$(curl -s --max-time 3 ipv4.icanhazip.com || hostname -I | awk '{print $1}')
    RAM=$(free -m | awk 'NR==2{printf "%s / %s MB", $3,$2}')
    CPU=$(top -bn1 | grep load | awk '{printf "%.2f", $(NF-2)}')
    UPTIME=$(uptime -p | sed 's/up //')
    CONECTADOS=$(ps -ef | grep -E "sshd|dropbear" | grep -v root | grep -v grep | wc -l)
    SUBDOMINIO=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "Ninguno (Opción 9)" )

    echo -e "${CYAN}================================================${NC}"
    echo -e "${GREEN}          PANEL PRINCIPAL GOLBERT VPS           ${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo -e "${YELLOW} Sistema OS : ${NC}$OS"
    echo -e "${YELLOW} IP Pública : ${NC}$IP"
    echo -e "${YELLOW} Subdominio : ${GREEN}$SUBDOMINIO${NC}"
    echo -e "${YELLOW} Memoria RAM: ${NC}$RAM"
    echo -e "${YELLOW} Conectados : ${GREEN}$CONECTADOS usuario(s) activos${NC}"
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
    echo -e "${GREEN}12)${NC}Instalar SlowDNS (DNSTT)"
    echo -e "${GREEN}13)${NC}Optimizar Servidor (Limpiar RAM)"
    echo -e "${GREEN}14)${NC}Configurar Banner SSH (Saludo)"
    echo -e "${GREEN}15)${NC}Actualizar Script (Desde GitHub)"
    echo -e "${GREEN}16)${NC}Auto-Inicio del Menú (Al Login)"
    echo -e "${GREEN}9) ${NC}Panel General VPS"
    echo -e "${CYAN}================================================${NC}"
    echo -e "${RED}88) Desinstalar Script${NC}"
    echo -e "${RED}0) Salir del Panel${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo -n -e "${YELLOW}Seleccione una opción: ${NC}"
    read opcion

    case $opcion in
        1|01) menu_ssh ;; 2|02) menu_xray_proto "VMess" ;; 3|03) menu_xray_proto "VLESS" ;; 4|04) menu_xray_proto "Trojan" ;;
        5|05) menu_checkuser ;; 6|06) menu_openvpn ;; 7|07) menu_install_php ;; 8|08) menu_bbr ;;
        10) menu_sshws ;; 11) menu_websocket ;; 12) menu_slowdns ;; 13) menu_optimizar ;; 14) menu_banner ;;
        15) menu_update ;; 16) menu_autostart ;;
        9|09) menu_panel_vps ;; 88) uninstall_script ;; x|X|0) clear; exit 0 ;;
        *) echo -e "\n${RED}[!] Opción inválida.${NC}"; sleep 1 ;;
    esac
done
