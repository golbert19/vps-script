#!/bin/bash
# ==========================================
# Golbert VPS Premium - Panel V5.0 LTS (Multi-Ubuntu)
# ==========================================

C_RST='\033[0m'; C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'
C_NEON_BLUE='\033[38;5;39m'; C_NEON_GREEN='\033[38;5;46m'; C_NEON_PURPLE='\033[38;5;141m'; C_NEON_YELLOW='\033[38;5;226m'
mkdir -p /etc/vps-manager

if [ -f /etc/os-release ]; then . /etc/os-release; UBUNTU_VERSION=$VERSION_ID; else UBUNTU_VERSION="24.04"; fi

generar_banner_usuario() {
    local u=$1; local exp=$2; local dias=$3; local limit=$4
    local base=$(cat /etc/issue.net 2>/dev/null)
    local banner_file="/etc/vps-manager/banner_${u}.net"
    echo -e "${base}<br><font color='cyan'>=======================</font><br><font color='yellow'>👤 Usuario:</font> <font color='white'>${u}</font><br><font color='yellow'>📅 Expira:</font> <font color='white'>${exp} (${dias} Días)</font><br><font color='yellow'>🔒 Límite:</font> <font color='white'>${limit} Conexiones</font><br><font color='cyan'>=======================</font><br>" > "$banner_file"
    sed -i "/Match User $u/d" /etc/ssh/sshd_config
    sed -i "/Banner \/etc\/vps-manager\/banner_${u}.net/d" /etc/ssh/sshd_config
    echo -e "\nMatch User $u\nBanner $banner_file" >> /etc/ssh/sshd_config
}

menu_ssh() {
    while true; do
        clear
        echo -e "${C_NEON_BLUE}╔══════════════════════════════════════════════╗${C_RST}"
        echo -e "${C_NEON_BLUE}║${C_NEON_GREEN}         🛰️ GESTION DE SSH (USUARIOS)         ${C_NEON_BLUE}║${C_RST}"
        echo -e "${C_NEON_BLUE}╠══════════════════════════════════════════════╣${C_RST}"
        echo -e "  ${C_NEON_YELLOW}1${C_RST} ➔ Crear Cuenta SSH (Normal / HWID)"
        echo -e "  ${C_NEON_YELLOW}2${C_RST} ➔ Eliminar Cuenta SSH"
        echo -e "  ${C_NEON_YELLOW}3${C_RST} ➔ Renovar Cuenta SSH"
        echo -e "  ${C_NEON_YELLOW}4${C_RST} ➔ Lista de Miembros y Vencimiento"
        echo -e "  ${C_NEON_YELLOW}5${C_RST} ➔ Verificar Conectados en Vivo"
        echo -e "  ${C_NEON_YELLOW}6${C_RST} ➔ Cambiar Límite de IPs (Cuenta SSH)"
        echo -e "  ${C_NEON_YELLOW}7${C_RST} ➔ Bloquear Cuenta SSH"
        echo -e "  ${C_NEON_YELLOW}8${C_RST} ➔ Desbloquear Cuenta SSH"
        echo -e "  ${C_NEON_YELLOW}9${C_RST} ➔ AutoKill (Desconectar multi-logins)"
        echo -e "${C_NEON_BLUE}╠══════════════════════════════════════════════╣${C_RST}"
        echo -e "  ${C_RED}0${C_RST} ➔ Volver al Menú Principal"
        echo -e "${C_NEON_BLUE}╚══════════════════════════════════════════════╝${C_RST}"
        read -p "Seleccione una opción: " opt
        case $opt in
            1) 
                clear; echo -e "${C_CYAN}================================================${C_RST}\n${C_YELLOW}      CREAR USUARIO SSH / HWID PROTECTION       ${C_RST}\n${C_CYAN}================================================${C_RST}"
                echo -e " [${C_GREEN}1${C_RST}] Cuenta Normal\n [${C_GREEN}2${C_RST}] Cuenta HWID"; read -p "Opción: " tipo_creacion
                read -p "Usuario: " user; read -p "Contraseña: " pass; read -p "Días: " dias; read -p "Límite Conexiones: " limite
                [ -z "$limite" ] && limite=1
                EXP_DATE=$(date -d "+$dias days" +"%Y-%m-%d")
                useradd -e $EXP_DATE -s /bin/false -M $user; echo "$user:$pass" | chpasswd
                echo "$limite" > "/etc/vps-manager/limite_${user}"
                if [ "$tipo_creacion" == "2" ]; then touch "/etc/vps-manager/hwid_${user}"; HWID_MSG="✅ (Bloqueado al Login)"; else rm -f "/etc/vps-manager/hwid_${user}"; HWID_MSG="❌ (Libre)"; fi
                generar_banner_usuario "$user" "$EXP_DATE" "$dias" "$limite"
                systemctl restart ssh 2>/dev/null
                
                # Extracción de datos de conexión (Mejorado)
                IP_V=$(curl -s ipv4.icanhazip.com); DOM=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "$IP_V" )
                NS_DOM=$( [ -f /etc/vps-manager/nsdomain ] && cat /etc/vps-manager/nsdomain || echo "No configurado" )
                PUB_KEY=$( [ -f /etc/vps-manager/slowdns/server.pub ] && cat /etc/vps-manager/slowdns/server.pub | tr -d '\r\n' || echo "No instalada" )
                OPENVPN_LINK="http://$DOM:2081"
                
                if [ -f /etc/zivpn/config.json ]; then
                    ZIVPN_PASS=$(grep '"config"' /etc/zivpn/config.json | awk -F'[' '{print $2}' | awk -F']' '{print $1}' | tr -d ' "')
                    [ -z "$ZIVPN_PASS" ] && ZIVPN_PASS="zi"
                else
                    ZIVPN_PASS="No instalado"
                fi

                clear; echo -e "${C_CYAN}================================================${C_RST}\n${C_GREEN}        ✅ CUENTA CREADA EXITOSAMENTE ✅        ${C_RST}\n${C_CYAN}================================================${C_RST}"
                echo -e " 👤 Usuario       : ${C_YELLOW}$user${C_RST}"
                echo -e " 🔑 Clave         : ${C_YELLOW}$pass${C_RST}"
                echo -e " 📅 Vence         : ${C_YELLOW}$EXP_DATE ($dias días)${C_RST}"
                echo -e " 🔒 Límite IPs    : ${C_YELLOW}$limite${C_RST}"
                echo -e " 🛡️ Protecc. HWID : ${C_YELLOW}$HWID_MSG${C_RST}"
                echo -e "${C_CYAN}------------------------------------------------${C_RST}"
                echo -e " 🌐 Host/IP       : ${C_YELLOW}$DOM${C_RST}"
                echo -e " 🌍 NS Domain     : ${C_YELLOW}$NS_DOM${C_RST}"
                echo -e " 🗝️ Pub Key (DNS) : ${C_YELLOW}$PUB_KEY${C_RST}"
                echo -e " 🔗 OpenVPN       : ${C_YELLOW}$OPENVPN_LINK${C_RST}"
                echo -e " ⚡ Zivpn Pass    : ${C_YELLOW}$ZIVPN_PASS${C_RST}"
                echo -e " 🎯 Puertos       : ${C_YELLOW}SSH(22) SSL(443) UDP(25000)${C_RST}"
                echo -e "                     ${C_YELLOW}Zivpn(6000-19999) DNSTT(53)${C_RST}"
                echo -e "${C_CYAN}================================================${C_RST}"; read -p "Copia los datos y presiona Enter..." ;;
            2) read -p "Usuario a eliminar: " user; userdel -f $user 2>/dev/null; rm -f /etc/vps-manager/banner_${user}.net /etc/vps-manager/limite_${user} /etc/vps-manager/hwid_${user}; sed -i "/Match User $user/,+1d" /etc/ssh/sshd_config; systemctl restart ssh 2>/dev/null; echo -e "${C_GREEN}[✔] Eliminado.${C_RST}"; sleep 2 ;;
            3) read -p "Usuario a renovar: " user; read -p "Nuevos días: " dias; EXP_DATE=$(date -d "+$dias days" +"%Y-%m-%d"); chage -E $EXP_DATE $user; limite=$(cat /etc/vps-manager/limite_${user} 2>/dev/null || echo "1"); generar_banner_usuario "$user" "$EXP_DATE" "$dias" "$limite"; systemctl restart ssh 2>/dev/null; echo -e "${C_GREEN}[✔] Renovado.${C_RST}"; sleep 2 ;;
            4) clear; echo -e "${C_CYAN}╔══════════════════════════════════════════════╗\n║${C_GREEN}       📋 LISTA DE USUARIOS Y VENCIMIENTO     ${C_CYAN}║\n╚══════════════════════════════════════════════╝${C_RST}"; printf "${C_YELLOW}%-15s %-15s %-15s${C_RST}\n" "USUARIO" "EXPIRA" "DÍAS RESTANTES"; echo -e "${C_CYAN}────────────────────────────────────────────────${C_RST}"; for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do exp_date=$(chage -l $user | grep "Account expires" | awk -F": " '{print $2}'); if [[ "$exp_date" != "never" && -n "$exp_date" ]]; then exp_fmt=$(date -d "$exp_date" "+%Y-%m-%d" 2>/dev/null); sec_exp=$(date -d "$exp_date" +%s 2>/dev/null); sec_now=$(date +%s); dias=$(( (sec_exp - sec_now) / 86400 )); [ $dias -lt 0 ] && dias=0; printf "%-15s %-15s %-15s\n" "$user" "$exp_fmt" "$dias Días"; else printf "%-15s %-15s %-15s\n" "$user" "Ilimitado" "∞"; fi; done; read -p "Enter..." ;;
            5) clear; echo -e "${C_YELLOW}      VERIFICAR CONEXIONES EN VIVO      ${C_RST}"; ps -ef | grep -E "sshd|dropbear" | grep -v root | grep -v grep | awk '{print $1}' | sort | uniq -c | awk '{print " 👤 "$2" -> "$1" conexión(es)"}'; read -p "Enter..." ;;
            6) read -p "Usuario: " user; read -p "Nuevo Límite de IPs: " n_limite; echo "$n_limite" > "/etc/vps-manager/limite_${user}"; echo -e "${C_GREEN}[✔] Actualizado.${C_RST}"; sleep 2 ;;
            7) read -p "Usuario a Bloquear: " user; usermod -L $user; pkill -u $user; echo -e "${C_RED}[✔] BLOQUEADO.${C_RST}"; sleep 2 ;;
            8) read -p "Usuario a Desbloquear: " user; usermod -U $user; echo -e "${C_GREEN}[✔] DESBLOQUEADO.${C_RST}"; sleep 2 ;;
            9) clear; echo -e "${C_YELLOW}[+] AutoKill (Buscando Multilogins)...${C_RST}"; for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do limite=$(cat /etc/vps-manager/limite_${user} 2>/dev/null || echo "999"); conexiones=$(ps -ef | grep sshd | grep "$user" | grep -v root | grep -v grep | wc -l); if [ "$conexiones" -gt "$limite" ]; then echo -e "${C_RED} ➔ $user excedió el límite. Desconectando...${C_RST}"; pkill -u "$user"; fi; done; echo -e "${C_GREEN}[✔] Listo.${C_RST}"; read -p "Enter..." ;;
            0) break ;;
            *) sleep 1 ;;
        esac
    done
}

menu_revendedores() {
    while true; do
        clear
        echo -e "${C_NEON_BLUE}╔══════════════════════════════════════════════╗${C_RST}"
        echo -e "${C_NEON_BLUE}║${C_NEON_GREEN}         🤝 GESTIÓN DE REVENDEDORES (BOT)     ${C_NEON_BLUE}║${C_RST}"
        echo -e "${C_NEON_BLUE}╠══════════════════════════════════════════════╣${C_RST}"
        echo -e "  ${C_NEON_YELLOW}1${C_RST} ➔ Agregar Revendedor / Recargar Créditos"
        echo -e "  ${C_NEON_YELLOW}2${C_RST} ➔ Eliminar Revendedor"
        echo -e "  ${C_NEON_YELLOW}3${C_RST} ➔ Lista de Revendedores Activos"
        echo -e "${C_NEON_BLUE}╠══════════════════════════════════════════════╣${C_RST}"
        echo -e "  ${C_RED}0${C_RST} ➔ Volver al Menú Principal"
        echo -e "${C_NEON_BLUE}╚══════════════════════════════════════════════╝${C_RST}"
        read -p "Opción: " ropt
        RES_FILE="/etc/vps-manager/telegram_bot/resellers.txt"
        case $ropt in
            1) read -p "ID de Telegram del Revendedor: " r_id; read -p "Cantidad de Créditos: " r_cred; mkdir -p /etc/vps-manager/telegram_bot; touch $RES_FILE; sed -i "/^$r_id:/d" $RES_FILE; echo "$r_id:$r_cred" >> $RES_FILE; echo -e "${C_GREEN}[✔] Revendedor guardado.${C_RST}"; sleep 2 ;;
            2) read -p "ID de Telegram a eliminar: " r_id; sed -i "/^$r_id:/d" $RES_FILE; echo -e "${C_RED}[✔] Revendedor eliminado.${C_RST}"; sleep 2 ;;
            3) clear; echo -e "${C_YELLOW}📋 LISTA DE REVENDEDORES:${C_RST}"; if [ -f "$RES_FILE" ]; then cat "$RES_FILE" | awk -F: '{print " 👤 ID: "$1" -> 💰 Créditos: "$2}'; else echo "No hay revendedores."; fi; read -p "Enter..." ;;
            0) break ;;
            *) sleep 1 ;;
        esac
    done
}

menu_instaladores() {
    while true; do
        clear
        echo -e "${C_NEON_PURPLE}╔══════════════════════════════════════════════╗${C_RST}"
        echo -e "${C_NEON_PURPLE}║${C_NEON_GREEN}    🛠️ GESTOR DE INSTALACIONES Y PROTOCOLOS   ${C_NEON_PURPLE}║${C_RST}"
        echo -e "${C_NEON_PURPLE}╠══════════════════════════════════════════════╣${C_RST}"
        echo -e "  ${C_NEON_YELLOW}1.${C_RST} 🛡️ Menú Xray (VMess)"
        echo -e "  ${C_NEON_YELLOW}2.${C_RST} 🛡️ Menú Xray (VLESS)"
        echo -e "  ${C_NEON_YELLOW}3.${C_RST} 🛡️ Menú Xray (Trojan)"
        echo -e "  ${C_NEON_YELLOW}4.${C_RST} 🌐 Instalar OpenVPN (Web Perfiles)"
        echo -e "  ${C_NEON_YELLOW}5.${C_RST} 🚀 Instalar HCR Nativo (Manager Pro)"
        echo -e "  ${C_NEON_YELLOW}6.${C_RST} 🎮 Instalar UDP Custom (Puerto 25000)"
        echo -e "  ${C_NEON_YELLOW}7.${C_RST} 🛸 Instalar SlowDNS (DNSTT)"
        echo -e "  ${C_NEON_YELLOW}8.${C_RST} 🌐 Instalar BHTTP Proxy (Puerto 8080)"
        echo -e "  ${C_NEON_YELLOW}9.${C_RST} 🔗 Instalar SSHWS / Websocket"
        echo -e "  ${C_NEON_YELLOW}10.${C_RST}🎮 Instalar BadVPN (Puertos 7300 y 7200)"
        echo -e "  ${C_NEON_YELLOW}11.${C_RST}🐘 Instalador PHP 8.5.12"
        echo -e "  ${C_NEON_YELLOW}12.${C_RST}🚀 Instalar Acelerador BBR"
        echo -e "  ${C_NEON_YELLOW}13.${C_RST}🛡️ Instalar Zivpn UDP (App Zivpn)"
        echo -e "${C_NEON_PURPLE}╠══════════════════════════════════════════════╣${C_RST}"
        echo -e "  ${C_RED}0.${C_RST} 🔙 Volver al Menú Principal"
        echo -e "${C_NEON_PURPLE}╚══════════════════════════════════════════════╝${C_RST}"
        read -p "Seleccione una opción: " hopt
        case $hopt in
            1) clear; wget -qO /tmp/xray_manager.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/xray_manager.sh && chmod +x /tmp/xray_manager.sh && bash /tmp/xray_manager.sh "VMess" ;;
            2) clear; wget -qO /tmp/xray_manager.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/xray_manager.sh && chmod +x /tmp/xray_manager.sh && bash /tmp/xray_manager.sh "VLESS" ;;
            3) clear; wget -qO /tmp/xray_manager.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/xray_manager.sh && chmod +x /tmp/xray_manager.sh && bash /tmp/xray_manager.sh "Trojan" ;;
            4) clear; wget -qO /tmp/setup_openvpn.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/setup_openvpn.sh && chmod +x /tmp/setup_openvpn.sh && bash /tmp/setup_openvpn.sh; read -p "Enter..." ;;
            5) clear; wget -qO /tmp/hcr.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/hcr.sh && chmod +x /tmp/hcr.sh && bash /tmp/hcr.sh ;;
            6) clear; wget -qO /tmp/udp_custom.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/udp_custom.sh && chmod +x /tmp/udp_custom.sh && bash /tmp/udp_custom.sh ;;
            7) clear; wget -qO /tmp/Slowdns.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/Slowdns.sh && chmod +x /tmp/Slowdns.sh && bash /tmp/Slowdns.sh ;;
            8) clear; wget -qO /tmp/bhttp.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/bhttp.sh && chmod +x /tmp/bhttp.sh && bash /tmp/bhttp.sh ;;
            9) clear; wget -qO /tmp/sshws.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/sshws.sh && chmod +x /tmp/sshws.sh && bash /tmp/sshws.sh; read -p "Enter..." ;;
            10) clear; wget -qO /tmp/badvpn.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/badvpn.sh && chmod +x /tmp/badvpn.sh && bash /tmp/badvpn.sh ;;
            11) clear; curl -sSL "https://raw.githubusercontent.com/golbert19/php-8.5.12-vps/main/install.sh?t=$(date +%s)" | sed '59s/[()]//g' | bash; read -p "Enter..." ;;
            12) clear; wget -qO /tmp/Bbr.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/Bbr.sh && chmod +x /tmp/Bbr.sh && bash /tmp/Bbr.sh; read -p "Enter..." ;;
            13) clear; wget -qO /tmp/zivpn.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/zivpn.sh && chmod +x /tmp/zivpn.sh && bash /tmp/zivpn.sh ;;
            0) break ;;
            *) sleep 1 ;;
        esac
    done
}

menu_webpanel() { clear; echo -e "${C_YELLOW}[+] Preparando Panel Web (Compatible Ubuntu 22/24/26)...${C_RST}"; wget -qO /tmp/webpanel.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/webpanel.sh && chmod +x /tmp/webpanel.sh && bash /tmp/webpanel.sh; }

menu_puertos() { 
    clear
    echo -e "${C_NEON_BLUE}╔══════════════════════════════════════════════╗\n║${C_NEON_GREEN}         🔍 ESTADO DE PUERTOS Y SERVICIOS     ${C_NEON_BLUE}║\n╚══════════════════════════════════════════════╝${C_RST}"
    puertos=(22 80 443 53 1194 2081 2083 8080 8880 8181 7300 7200)
    nombres=("SSH (OpenSSH)" "HTTP / Xray WS" "SSL / VLESS / Trojan" "DNS (SlowDNS)" "OpenVPN TCP" "OpenVPN Web" "Trojan TLS" "BHTTP Custom" "HCR Proxy PRO" "Web Panel UI" "BadVPN (Game 7300)" "BadVPN (Game 7200)")
    
    for i in "${!puertos[@]}"; do 
        p=${puertos[$i]}; n=${nombres[$i]}
        if ss -lntp 2>/dev/null | grep -q ":$p " || ss -lnup 2>/dev/null | grep -q ":$p "; then 
            echo -e "  🔹 [${C_NEON_GREEN}ACTIVO   ${C_RST}] Puerto ${C_NEON_YELLOW}$p${C_RST} ➔ $n"
        else 
            echo -e "  🔸 [${C_RED}INACTIVO ${C_RST}] Puerto ${C_NEON_YELLOW}$p${C_RST} ➔ $n"
        fi
    done
    
    if systemctl is-active --quiet udp-custom || ss -lnup 2>/dev/null | grep -q ":25000 "; then
        echo -e "  🔹 [${C_NEON_GREEN}ACTIVO   ${C_RST}] Puerto ${C_NEON_YELLOW}25000${C_RST} ➔ UDP Custom"
    else
        echo -e "  🔸 [${C_RED}INACTIVO ${C_RST}] Puerto ${C_NEON_YELLOW}25000${C_RST} ➔ UDP Custom"
    fi

    if systemctl is-active --quiet zivpn.service || ss -lnup 2>/dev/null | grep -q ":5667 "; then
        echo -e "  🔹 [${C_NEON_GREEN}ACTIVO   ${C_RST}] Puerto ${C_NEON_YELLOW}6000-19999${C_RST} ➔ Zivpn UDP"
    else
        echo -e "  🔸 [${C_RED}INACTIVO ${C_RST}] Puerto ${C_NEON_YELLOW}6000-19999${C_RST} ➔ Zivpn UDP"
    fi
    
    echo -e "${C_NEON_BLUE}────────────────────────────────────────────────${C_RST}"
    read -p "Presione Enter para regresar..."
}

menu_bot() { clear; echo -e "${C_YELLOW}[+] Configurando Bot...${C_RST}"; wget -qO /tmp/bot.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/bot.sh && chmod +x /tmp/bot.sh && bash /tmp/bot.sh; read -p "Enter..." ;}
menu_dominio() { clear; read -p "Subdominio (Ej: vps.dominio.com): " ndom; echo "$ndom" > /etc/vps-manager/dominio; systemctl stop ws-python xray stunnel4 2>/dev/null; fuser -k 80/tcp 2>/dev/null; apt install -y certbot >/dev/null 2>&1; certbot certonly --standalone -d "$ndom" --non-interactive --agree-tos -m "admin@$ndom"; if [ -d "/etc/letsencrypt/live/$ndom" ]; then mkdir -p /etc/xray /etc/stunnel; cp /etc/letsencrypt/live/$ndom/fullchain.pem /etc/xray/server.crt; cp /etc/letsencrypt/live/$ndom/privkey.pem /etc/xray/server.key; cat /etc/xray/server.crt /etc/xray/server.key > /etc/stunnel/stunnel.pem; echo -e "${C_GREEN}[✔] SSL Instalado.${C_RST}"; fi; systemctl start ws-python xray stunnel4 2>/dev/null; sleep 3; }
menu_update() { clear; wget -qO /tmp/menu.sh "https://raw.githubusercontent.com/golbert19/vps-script/main/menu.sh"; if [ -s /tmp/menu.sh ]; then mv /tmp/menu.sh /usr/local/bin/menu; chmod +x /usr/local/bin/menu; echo -e "${C_GREEN}[✔] Actualizado!${C_RST}"; sleep 2; exec menu; fi; }
menu_autostart() { clear; grep -q "menu" /root/.bashrc && echo -e "${C_GREEN}[✔] Ya activo.${C_RST}" || (echo -e "\nmenu" >> /root/.bashrc; echo -e "${C_GREEN}[✔] Activado.${C_RST}"); read -p "Enter..." ;}
menu_banner() { clear; echo -e "${C_NEON_BLUE}╔══════════════════════════════════════════════╗\n║${C_NEON_GREEN}         GESTOR DE BANNER BASE HTML           ${C_NEON_BLUE}║\n╚══════════════════════════════════════════════╝${C_RST}\n  ${C_NEON_YELLOW}1.${C_RST} Banner por Defecto\n  ${C_NEON_YELLOW}2.${C_RST} Personalizado HTML\n"; read -p "Opción: " opt_ban; case $opt_ban in 1) TEXTO="<br><font color='cyan'><b>🌟 BIENVENIDO A GOLBERT VPS 🌟</b></font><br>" ;; 2) echo -e "Pega HTML: "; read -r TEXTO ;; *) TEXTO="Bienvenido" ;; esac; echo "$TEXTO" > /etc/issue.net; echo -e "${C_GREEN}[✔] Banner Global guardado.${C_RST}"; read -p "Presione Enter..." ; }

menu_info() {
    clear
    OS_NAME=$(cat /etc/os-release | grep -w PRETTY_NAME | cut -d= -f2 | tr -d '"')
    KERNEL=$(uname -r)
    ARCH=$(uname -m)
    UPTIME=$(uptime -p)
    CPU_MODEL=$(lscpu | grep "Model name" | awk -F':' '{print $2}' | xargs)
    CPU_CORES=$(nproc)
    DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
    DISK_USED=$(df -h / | awk 'NR==2{print $3}')
    DISK_PER=$(df -h / | awk 'NR==2{print $5}')
    
    echo -e "${C_NEON_BLUE}╔══════════════════════════════════════════════╗${C_RST}"
    echo -e "${C_NEON_BLUE}║${C_NEON_GREEN}       🖥️ INFORMACIÓN TÉCNICA DEL VPS         ${C_NEON_BLUE}║${C_RST}"
    echo -e "${C_NEON_BLUE}╠══════════════════════════════════════════════╣${C_RST}"
    echo -e "  ${C_NEON_YELLOW}💻 Sistema Operativo :${C_RST} $OS_NAME (Ubuntu $UBUNTU_VERSION LTS)"
    echo -e "  ${C_NEON_YELLOW}⚙️ Arquitectura      :${C_RST} $ARCH ($KERNEL)"
    echo -e "  ${C_NEON_YELLOW}⏱️ Tiempo Encendido  :${C_RST} $UPTIME"
    echo -e "  ${C_NEON_YELLOW}🧠 Procesador (CPU)  :${C_RST} $CPU_MODEL"
    echo -e "  ${C_NEON_YELLOW}⚡ Núcleos Lógicos   :${C_RST} $CPU_CORES vCPU(s)"
    echo -e "  ${C_NEON_YELLOW}💾 Almacenamiento    :${C_RST} $DISK_USED / $DISK_TOTAL ($DISK_PER Usado)"
    echo -e "${C_NEON_BLUE}╚══════════════════════════════════════════════╝${C_RST}"
    read -p "Presione Enter para regresar..."
}

uninstall_script() { clear; read -p "⚠️ ¿Desinstalar todo? (s/n): " conf; if [[ "$conf" == "s" || "$conf" == "S" ]]; then rm -rf /etc/vps-manager; rm -f /usr/local/bin/menu; echo -e "${C_GREEN}Eliminado.${C_RST}"; exit 0; fi; }

draw_bar() { 
    local perc=$1; local filled=$((perc / 10)); local empty=$((10 - filled)); local bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    for ((i=0; i<empty; i++)); do bar="${bar}░"; done
    echo -e "[$bar] ${perc}%" 
}

while true; do
    clear
    OS=$(cat /etc/os-release | grep -w PRETTY_NAME | head -n 1 | cut -d "=" -f 2 | sed 's/"//g')
    IP=$(curl -s --max-time 3 ipv4.icanhazip.com || hostname -I | awk '{print $1}')
    RAM_TOTAL=$(free -m | awk 'NR==2{print $2}'); RAM_USED=$(free -m | awk 'NR==2{print $3}')
    RAM_PER=$((RAM_USED * 100 / RAM_TOTAL)); RAM_STR=$(free -m | awk 'NR==2{printf "%s / %s MB", $3,$2}')
    RAM_BAR=$(draw_bar $RAM_PER)
    CPU_PER=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d'.' -f1); [ -z "$CPU_PER" ] && CPU_PER=0
    CPU_BAR=$(draw_bar $CPU_PER)
    CONECTADOS=$(ps -ef | grep -E "sshd|dropbear" | grep -v root | grep -v grep | wc -l)
    SUBDOMINIO=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "No Configurado" )

    echo -e "${C_NEON_BLUE}╔══════════════════════════════════════════════╗${C_RST}"
    echo -e "${C_NEON_BLUE}║ ${C_NEON_YELLOW}🌟 GOLBERT VPS PREMIUM - PANEL V5.0 LTS 🌟   ${C_NEON_BLUE}║${C_RST}"
    echo -e "${C_NEON_BLUE}╠══════════════════════════════════════════════╣${C_RST}"
    echo -e "${C_NEON_BLUE}║ ${C_NEON_GREEN}💻 SO         :${C_RST} $OS"
    echo -e "${C_NEON_BLUE}║ ${C_NEON_GREEN}🌐 IP         :${C_RST} $IP"
    echo -e "${C_NEON_BLUE}║ ${C_NEON_GREEN}🎯 Dominio    :${C_RST} $SUBDOMINIO"
    echo -e "${C_NEON_BLUE}║ ${C_NEON_GREEN}🧠 CPU Uso    :${C_RST} $CPU_BAR"
    echo -e "${C_NEON_BLUE}║ ${C_NEON_GREEN}⚡ RAM Uso    :${C_RST} $RAM_BAR ($RAM_STR)"
    echo -e "${C_NEON_BLUE}║ ${C_NEON_GREEN}👥 Conectados :${C_RST} $CONECTADOS usuarios activos"
    echo -e "${C_NEON_BLUE}╠══════════════════════════════════════════════╣${C_RST}"
    echo -e "${C_NEON_PURPLE}  [ GESTIÓN DE CUENTAS ]${C_RST}"
    echo -e "  ${C_NEON_YELLOW}1.${C_RST} 👤 Gestión de SSH (Usuarios, Límite, HWID)"
    echo -e "  ${C_NEON_YELLOW}2.${C_RST} 🤝 Gestión de Revendedores (Créditos)"
    echo -e "${C_NEON_BLUE}╠══════════════════════════════════════════════╣${C_RST}"
    echo -e "${C_NEON_PURPLE}  [ HERRAMIENTAS Y SISTEMA ]${C_RST}"
    echo -e "  ${C_NEON_YELLOW}3.${C_RST} 🛠️ Gestor de Instalaciones y Protocolos"
    echo -e "  ${C_NEON_YELLOW}4.${C_RST} 🎨 Configurar Banner HTML de Bienvenida"
    echo -e "  ${C_NEON_YELLOW}5.${C_RST} 🔍 Monitor de Puertos (Activos / Inactivos)"
    echo -e "  ${C_NEON_YELLOW}6.${C_RST} ⚙️ Configurar Subdominio VPS y SSL"
    echo -e "  ${C_NEON_YELLOW}7.${C_RST} 🤖 Vincular Bot de Telegram"
    echo -e "  ${C_NEON_YELLOW}8.${C_RST} 🌐 Generar Panel Web (Dashboard UI)"
    echo -e "  ${C_NEON_YELLOW}9.${C_RST} 🔄 Actualizar Panel (Desde GitHub)"
    echo -e "  ${C_NEON_YELLOW}10.${C_RST}🤖 Activar Auto-Inicio al Loguearse"
    echo -e "  ${C_NEON_YELLOW}11.${C_RST}🖥️ Especificaciones y Capacidad del VPS"
    echo -e "${C_NEON_BLUE}╠══════════════════════════════════════════════╣${C_RST}"
    echo -e "  ${C_RED}88.${C_RST} ❌ Desinstalar Script   |   ${C_RED}0.${C_RST} 🚪 Salir"
    echo -e "${C_NEON_BLUE}╚══════════════════════════════════════════════╝${C_RST}"
    echo -n -e "${C_YELLOW}Seleccione una opción: ${C_RST}"
    read opcion

    case $opcion in
        1) menu_ssh ;; 2) menu_revendedores ;; 3) menu_instaladores ;; 4) menu_banner ;; 5) menu_puertos ;; 
        6) menu_dominio ;; 7) menu_bot ;; 8) menu_webpanel ;; 9) menu_update ;; 10) menu_autostart ;; 11) menu_info ;;
        88) uninstall_script ;; 0) clear; exit 0 ;;
        *) echo -e "\n${C_RED}[!] Opción inválida.${C_RST}"; sleep 1 ;;
    esac
done
