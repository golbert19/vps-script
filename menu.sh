#!/bin/bash
# ==========================================
# Golbert VPS Premium - Panel V5.0 LTS
# ==========================================

C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_PURP='\033[1;35m'; C_NC='\033[0m'
mkdir -p /etc/vps-manager

# FUNCIÓN: Inyectar datos al Banner del Usuario
generar_banner_usuario() {
    local u=$1; local exp=$2; local dias=$3
    local base=$(cat /etc/issue.net 2>/dev/null)
    local banner_file="/etc/vps-manager/banner_${u}.net"
    
    echo -e "${base}<br><font color='cyan'>=======================</font><br><font color='yellow'>👤 Usuario:</font> <font color='white'>${u}</font><br><font color='yellow'>📅 Expira:</font> <font color='white'>${exp} (${dias} Días)</font><br><font color='cyan'>=======================</font><br>" > "$banner_file"
    
    sed -i "/Match User $u/d" /etc/ssh/sshd_config
    sed -i "/Banner \/etc\/vps-manager\/banner_${u}.net/d" /etc/ssh/sshd_config
    echo -e "\nMatch User $u\nBanner $banner_file" >> /etc/ssh/sshd_config
}

# FUNCIÓN: Actualizar los banners de TODOS los usuarios
actualizar_todos_banners() {
    for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
        exp_date=$(chage -l $user | grep "Account expires" | awk -F": " '{print $2}')
        if [[ "$exp_date" != "never" && -n "$exp_date" ]]; then
            exp_fmt=$(date -d "$exp_date" "+%Y-%m-%d" 2>/dev/null || echo "$exp_date")
            sec_exp=$(date -d "$exp_date" +%s 2>/dev/null || echo 0)
            sec_now=$(date +%s)
            dias=$(( (sec_exp - sec_now) / 86400 ))
            [ $dias -lt 0 ] && dias=0
            generar_banner_usuario "$user" "$exp_fmt" "$dias"
        fi
    done
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
}

menu_ssh() {
    while true; do
        clear; echo -e "${C_CYAN}╔══════════════════════════════════════════════╗${C_NC}"
        echo -e "${C_CYAN}║${C_GREEN}             GESTOR DE SSH / DROPBEAR         ${C_CYAN}║${C_NC}"
        echo -e "${C_CYAN}╠══════════════════════════════════════════════╣${C_NC}"
        echo -e "${C_YELLOW}  1)${C_NC} Crear nuevo usuario SSH"
        echo -e "${C_YELLOW}  2)${C_NC} Eliminar usuario SSH"
        echo -e "${C_YELLOW}  3)${C_NC} Renovar usuario SSH"
        echo -e "${C_YELLOW}  4)${C_NC} Lista de conectados"
        echo -e "${C_YELLOW}  5)${C_NC} Lista de usuarios y vencimiento"
        echo -e "${C_YELLOW}  0)${C_NC} Volver"
        echo -e "${C_CYAN}╚══════════════════════════════════════════════╝${C_NC}"; read -p "Opción: " opt
        case $opt in
            1) 
                read -p "Usuario: " user; read -p "Contraseña: " pass; read -p "Días: " dias
                EXP_DATE=$(date -d "+$dias days" +"%Y-%m-%d")
                useradd -e $EXP_DATE -s /bin/false -M $user; echo "$user:$pass" | chpasswd
                
                # Crear Banner único para este cliente
                generar_banner_usuario "$user" "$EXP_DATE" "$dias"
                systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null

                IP_V=$(curl -s ipv4.icanhazip.com); DOM=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "$IP_V" )
                NS_DOM=$( [ -f /etc/vps-manager/nsdomain ] && cat /etc/vps-manager/nsdomain || echo "No config" ); PUB_KEY=$( [ -f /etc/vps-manager/slowdns/server.pub ] && cat /etc/vps-manager/slowdns/server.pub || echo "No instalada" )
                
                clear; echo -e "${C_CYAN}================================================${C_NC}\n${C_GREEN}        ✅ CUENTA CREADA EXITOSAMENTE ✅        ${C_NC}\n${C_CYAN}================================================${C_NC}"
                echo -e " 👤 Usuario       : $user\n 🔑 Clave         : $pass\n 📅 Vence         : $EXP_DATE ($dias días)\n\n 🌐 Host/IP       : $DOM\n 🌐 Subdominio NS : $NS_DOM\n 🔐 Pub Key (DNS) : $PUB_KEY\n 🎯 Puertos       : 22, 80, 443, 53, 8080\n${C_CYAN}================================================${C_NC}"
                read -p "Copia los datos y presiona Enter..." ;;
            2) 
                read -p "Usuario a eliminar: " user
                userdel -f $user 2>/dev/null
                rm -f /etc/vps-manager/banner_${user}.net
                sed -i "/Match User $user/,+1d" /etc/ssh/sshd_config
                systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
                echo -e "${C_GREEN}[✔] Eliminado.${C_NC}"; sleep 2 ;;
            3) 
                read -p "Usuario a renovar: " user; read -p "Nuevos días: " dias
                EXP_DATE=$(date -d "+$dias days" +"%Y-%m-%d")
                chage -E $EXP_DATE $user
                generar_banner_usuario "$user" "$EXP_DATE" "$dias"
                systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
                echo -e "${C_GREEN}[✔] Renovado.${C_NC}"; sleep 2 ;;
            4) echo -e "${C_YELLOW}Conectados:${C_NC}"; ps -ef | grep -E "sshd|dropbear" | grep -v root | grep -v grep | awk '{print $1}' | sort | uniq -c; read -p "Enter..." ;;
            5) 
                clear
                echo -e "${C_CYAN}╔══════════════════════════════════════════════╗${C_NC}"
                echo -e "${C_CYAN}║${C_GREEN}       📋 LISTA DE USUARIOS Y VENCIMIENTO     ${C_CYAN}║${C_NC}"
                echo -e "${C_CYAN}╚══════════════════════════════════════════════╝${C_NC}"
                printf "${C_YELLOW}%-15s %-15s %-15s${C_NC}\n" "USUARIO" "EXPIRA" "DÍAS RESTANTES"
                echo -e "${C_CYAN}────────────────────────────────────────────────${C_NC}"
                for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
                    exp_date=$(chage -l $user | grep "Account expires" | awk -F": " '{print $2}')
                    if [[ "$exp_date" != "never" && -n "$exp_date" ]]; then
                        exp_fmt=$(date -d "$exp_date" "+%Y-%m-%d" 2>/dev/null || echo "$exp_date")
                        sec_exp=$(date -d "$exp_date" +%s 2>/dev/null || echo 0)
                        sec_now=$(date +%s)
                        dias=$(( (sec_exp - sec_now) / 86400 ))
                        [ $dias -lt 0 ] && dias=0
                        printf "%-15s %-15s %-15s\n" "$user" "$exp_fmt" "$dias Días"
                    else
                        printf "%-15s %-15s %-15s\n" "$user" "Ilimitado" "∞"
                    fi
                done
                echo -e "${C_CYAN}────────────────────────────────────────────────${C_NC}"
                read -p "Presione Enter para continuar..."
                ;;
            0) break ;; *) echo -e "${C_RED}[!] Inválido.${C_NC}"; sleep 1 ;;
        esac
    done
}

menu_xray_proto() { clear; echo -e "${C_YELLOW}[+] Iniciando Módulo de $1...${C_NC}"; wget -qO /tmp/xray_manager.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/xray_manager.sh && chmod +x /tmp/xray_manager.sh && bash /tmp/xray_manager.sh "$1"; }
menu_checkuser() { clear; echo -e "${C_YELLOW}Total SSH:${C_NC} $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)\n\n${C_YELLOW}Expirados:${C_NC}"; for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do exp=$(chage -l $user | grep "Account expires" | awk -F": " '{print $2}'); if [[ "$exp" != "never" ]]; then if [ $(date +%s) -ge $(date -d "$exp" +%s 2>/dev/null || echo 9999999999) ]; then echo -e "${C_RED}- $user (Expiró: $exp)${C_NC}"; fi; fi; done; read -p "Enter..."; }
menu_openvpn() { clear; echo -e "${C_YELLOW}[+] Instalando OpenVPN...${C_NC}"; wget -qO /tmp/setup_openvpn.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/setup_openvpn.sh && chmod +x /tmp/setup_openvpn.sh && bash /tmp/setup_openvpn.sh; iptables -I INPUT -p tcp --dport 2081 -j ACCEPT; iptables-save > /etc/iptables.up.rules 2>/dev/null; IP_ACTUAL=$(curl -s ipv4.icanhazip.com); DOM=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "$IP_ACTUAL" ); echo -e "\n${C_GREEN}[✔] ¡Servidor Web Operativo!${C_NC}\n🔗 ${C_YELLOW}Perfiles (.ovpn):${C_NC} http://$DOM:2081\n"; read -p "Enter..."; }
menu_puertos() { clear; echo -e "${C_CYAN}╔══════════════════════════════════════════════╗\n║${C_GREEN}         🔍 ESTADO DE PUERTOS Y SERVICIOS     ${C_CYAN}║\n╚══════════════════════════════════════════════╝${C_NC}"; puertos=(22 80 443 53 1194 2081 2083 7300 8080); nombres=("SSH (OpenSSH)" "HTTP / Xray WS" "SSL / VLESS / Trojan" "DNS (SlowDNS)" "OpenVPN TCP" "OpenVPN Web" "Trojan TLS" "BadVPN UDPGW" "BHTTP Custom"); for i in "${!puertos[@]}"; do p=${puertos[$i]}; n=${nombres[$i]}; if ss -lntp 2>/dev/null | grep -q ":$p " || ss -lnup 2>/dev/null | grep -q ":$p "; then echo -e "  🔹 [${C_GREEN}ACTIVO   ${C_NC}] Puerto ${C_YELLOW}$p${C_NC} ➔ $n"; else echo -e "  🔸 [${C_RED}INACTIVO ${C_NC}] Puerto ${C_YELLOW}$p${C_NC} ➔ $n"; fi; done; echo -e "${C_CYAN}────────────────────────────────────────────────${C_NC}"; read -p "Presione Enter para regresar..."; }

menu_herramientas() {
    while true; do
        clear
        echo -e "${C_CYAN}╔══════════════════════════════════════════════╗${C_NC}"
        echo -e "${C_CYAN}║${C_GREEN}          🛠️ HERRAMIENTAS E INSTALADORES      ${C_CYAN}║${C_NC}"
        echo -e "${C_CYAN}╠══════════════════════════════════════════════╣${C_NC}"
        echo -e "  ${C_YELLOW}1.${C_NC} 🎮 Instalar BadVPN (UDPGW para Juegos)"
        echo -e "  ${C_YELLOW}2.${C_NC} 🚀 Instalar Acelerador BBR"
        echo -e "  ${C_YELLOW}3.${C_NC} 🛸 Instalar SlowDNS (DNSTT)"
        echo -e "  ${C_YELLOW}4.${C_NC} 🔗 Instalar SSHWS (Proxy SSL)"
        echo -e "  ${C_YELLOW}5.${C_NC} 🔗 Instalar Websocket"
        echo -e "  ${C_YELLOW}6.${C_NC} 🌐 Instalar BHTTP Proxy (Puerto 8080)"
        echo -e "  ${C_YELLOW}7.${C_NC} 🐘 Instalador PHP 8.5.12"
        echo -e "  ${C_YELLOW}8.${C_NC} 🎨 Configurar Banner Global Base"
        echo -e "  ${C_YELLOW}9.${C_NC} 🧹 Optimizar Servidor (Limpiar RAM)"
        echo -e "${C_CYAN}╠══════════════════════════════════════════════╣${C_NC}"
        echo -e "  ${C_RED}0.${C_NC} 🔙 Volver al Menú Principal"
        echo -e "${C_CYAN}╚══════════════════════════════════════════════╝${C_NC}"
        read -p "Seleccione una opción: " hopt
        case $hopt in
            1) clear; echo -e "${C_YELLOW}[+] Instalando BadVPN...${C_NC}"; wget -qO /tmp/badvpn.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/badvpn.sh && chmod +x /tmp/badvpn.sh && bash /tmp/badvpn.sh ;;
            2) clear; wget -qO /tmp/Bbr.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/Bbr.sh && chmod +x /tmp/Bbr.sh && bash /tmp/Bbr.sh; read -p "Enter..." ;;
            3) clear; wget -qO /tmp/Slowdns.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/Slowdns.sh && chmod +x /tmp/Slowdns.sh && bash /tmp/Slowdns.sh ;;
            4) clear; wget -qO /tmp/sshws.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/sshws.sh && chmod +x /tmp/sshws.sh && bash /tmp/sshws.sh; read -p "Enter..." ;;
            5) clear; wget -qO /tmp/websocket.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/websocket.sh && chmod +x /tmp/websocket.sh && bash /tmp/websocket.sh; read -p "Enter..." ;;
            6) clear; echo -e "${C_YELLOW}[+] Instalando BHTTP Proxy...${C_NC}"; wget -qO /tmp/bhttp.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/bhttp.sh && chmod +x /tmp/bhttp.sh && bash /tmp/bhttp.sh ;;
            7) clear; echo -e "${C_YELLOW}[+] Instalando PHP 8.5.12...${C_NC}"; curl -sSL "https://raw.githubusercontent.com/golbert19/php-8.5.12-vps/main/install.sh?t=$(date +%s)" | sed '59s/[()]//g' | bash; read -p "Enter..." ;;
            8) 
                clear
                echo -e "${C_CYAN}╔══════════════════════════════════════════════╗${C_NC}"
                echo -e "${C_CYAN}║${C_GREEN}         GESTOR DE BANNER BASE HTML           ${C_CYAN}║${C_NC}"
                echo -e "${C_CYAN}╚══════════════════════════════════════════════╝${C_NC}"
                echo -e "  ${C_YELLOW}1.${C_NC} Banner por Defecto"
                echo -e "  ${C_YELLOW}2.${C_NC} Banner Personalizado HTML"
                echo -e "${C_CYAN}────────────────────────────────────────────────${C_NC}"
                read -p "Seleccione una opción: " opt_ban
                case $opt_ban in
                    1) TEXTO="<br><font color='cyan'><b>🌟 BIENVENIDO A GOLBERT VPS 🌟</b></font><br><font color='green'>Conexión Segura y Estable</font><br>" ;;
                    2) echo -e "Escribe tu mensaje HTML: "; read -r TEXTO ;;
                    *) TEXTO="Bienvenido al servidor" ;;
                esac
                
                # Guardar el global
                echo "$TEXTO" > /etc/issue.net
                
                # ¡MAGIA! Actualiza todos los usuarios creados con el nuevo banner + sus datos de expiración
                actualizar_todos_banners
                
                echo -e "${C_GREEN}[✔] Banner Global aplicado a TODOS los usuarios.${C_NC}"; read -p "Presione Enter..." 
                ;;
            9) clear; echo -e "${C_YELLOW}[+] Optimizando RAM...${C_NC}"; sync; echo 3 > /proc/sys/vm/drop_caches; apt clean -y >/dev/null 2>&1; echo -e "${C_GREEN}[✔] Listo.${C_NC}"; read -p "Enter..." ;;
            0) break ;;
            *) echo -e "\n${C_RED}[!] Opción inválida.${C_NC}"; sleep 1 ;;
        esac
    done
}

menu_bot() { clear; echo -e "${C_YELLOW}[+] Configurando Bot de Telegram...${C_NC}"; wget -qO /tmp/bot.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/bot.sh && chmod +x /tmp/bot.sh && bash /tmp/bot.sh; read -p "Enter..."; }
menu_dominio() { clear; echo -e "${C_YELLOW}Ingrese su subdominio (Ej: vps.dominio.com)${C_NC}"; read -p "Subdominio: " ndom; echo "$ndom" > /etc/vps-manager/dominio; echo -e "\n${C_YELLOW}[+] Generando SSL Let's Encrypt...${C_NC}"; systemctl stop ws-python xray stunnel4 2>/dev/null; fuser -k 80/tcp 2>/dev/null; apt update -y && apt install -y certbot >/dev/null 2>&1; certbot certonly --standalone -d "$ndom" --non-interactive --agree-tos -m "admin@$ndom"; if [ -d "/etc/letsencrypt/live/$ndom" ]; then mkdir -p /etc/xray /etc/stunnel; cp /etc/letsencrypt/live/$ndom/fullchain.pem /etc/xray/server.crt; cp /etc/letsencrypt/live/$ndom/privkey.pem /etc/xray/server.key; cat /etc/xray/server.crt /etc/xray/server.key > /etc/stunnel/stunnel.pem; echo -e "${C_GREEN}[✔] SSL Instalado.${C_NC}"; else echo -e "${C_RED}[!] Error SSL.${C_NC}"; fi; systemctl start ws-python xray stunnel4 2>/dev/null; systemctl restart xray 2>/dev/null; systemctl restart stunnel4 2>/dev/null; sleep 3; }
menu_update() { clear; echo -e "${C_YELLOW}[+] Actualizando...${C_NC}"; wget -qO /tmp/menu.sh "https://raw.githubusercontent.com/golbert19/vps-script/main/menu.sh"; if [ -s /tmp/menu.sh ]; then mv /tmp/menu.sh /usr/local/bin/menu; chmod +x /usr/local/bin/menu; echo -e "${C_GREEN}[✔] Actualizado!${C_NC}"; sleep 2; exec menu; fi; }
menu_autostart() { clear; grep -q "menu" /root/.bashrc && echo -e "${C_GREEN}[✔] Ya activo.${C_NC}" || (echo -e "\nmenu" >> /root/.bashrc; echo -e "${C_GREEN}[✔] Activado.${C_NC}"); read -p "Enter..."; }
menu_info() { clear; echo -e "${C_CYAN}================================================\n${C_YELLOW}OS:${C_NC} $(cat /etc/os-release | grep -w PRETTY_NAME | cut -d= -f2 | tr -d '\"')\n${C_YELLOW}IP:${C_NC} $(curl -s ipv4.icanhazip.com)\n${C_YELLOW}RAM:${C_NC} $(free -m | awk 'NR==2{printf "%s / %s MB", $3,$2}')\n${C_CYAN}================================================${C_NC}"; read -p "Enter..."; }
uninstall_script() { clear; read -p "⚠️ ¿Desinstalar todo? (s/n): " conf; if [[ "$conf" == "s" || "$conf" == "S" ]]; then rm -rf /etc/vps-manager; rm -f /usr/local/bin/menu; echo -e "${C_GREEN}Script eliminado.${C_NC}"; exit 0; fi; }

# Función para dibujar barra de progreso visual
draw_bar() {
    local perc=$1; local filled=$((perc / 10)); local empty=$((10 - filled)); local bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done; for ((i=0; i<empty; i++)); do bar="${bar}░"; done; echo -e "[$bar] ${perc}%"
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

    echo -e "${C_CYAN}╔══════════════════════════════════════════════╗${C_NC}"
    echo -e "${C_CYAN}║ ${C_YELLOW}🌟 GOLBERT VPS PREMIUM - PANEL V5.0 LTS 🌟   ${C_CYAN}║${C_NC}"
    echo -e "${C_CYAN}╠══════════════════════════════════════════════╣${C_NC}"
    echo -e "${C_CYAN}║ ${C_GREEN}💻 SO         :${C_NC} $OS"
    echo -e "${C_CYAN}║ ${C_GREEN}🌐 IP         :${C_NC} $IP"
    echo -e "${C_CYAN}║ ${C_GREEN}🎯 Dominio    :${C_NC} $SUBDOMINIO"
    echo -e "${C_CYAN}║ ${C_GREEN}🧠 CPU Uso    :${C_NC} $CPU_BAR"
    echo -e "${C_CYAN}║ ${C_GREEN}⚡ RAM Uso    :${C_NC} $RAM_BAR ($RAM_STR)"
    echo -e "${C_CYAN}║ ${C_GREEN}👥 Conectados :${C_NC} $CONECTADOS usuarios activos"
    echo -e "${C_CYAN}╠══════════════════════════════════════════════╣${C_NC}"
    echo -e "${C_PURP}  [ GESTIÓN DE CUENTAS Y PROTOCOLOS ]${C_NC}"
    echo -e "  ${C_YELLOW}1.${C_NC} 👤 Menú SSH / Dropbear"
    echo -e "  ${C_YELLOW}2.${C_NC} 🛡️ Menú Xray (VMess)"
    echo -e "  ${C_YELLOW}3.${C_NC} 🛡️ Menú Xray (VLESS)"
    echo -e "  ${C_YELLOW}4.${C_NC} 🛡️ Menú Xray (Trojan)"
    echo -e "  ${C_YELLOW}5.${C_NC} 🌐 Menú OpenVPN (Web Perfiles)"
    echo -e "  ${C_YELLOW}6.${C_NC} 👥 Monitor de Usuarios Expirados"
    echo -e "${C_CYAN}╠══════════════════════════════════════════════╣${C_NC}"
    echo -e "${C_PURP}  [ HERRAMIENTAS Y SISTEMA ]${C_NC}"
    echo -e "  ${C_YELLOW}7.${C_NC} 🛠️ Herramientas e Instaladores"
    echo -e "  ${C_YELLOW}8.${C_NC} 🔍 Monitor de Puertos (Activos / Inactivos)"
    echo -e "  ${C_YELLOW}9.${C_NC} ⚙️ Configurar Subdominio VPS y SSL"
    echo -e "  ${C_YELLOW}10.${C_NC}🤖 Vincular Bot de Telegram"
    echo -e "  ${C_YELLOW}11.${C_NC}🔄 Actualizar Panel (Desde GitHub)"
    echo -e "  ${C_YELLOW}12.${C_NC}🤖 Activar Auto-Inicio al Loguearse"
    echo -e "  ${C_YELLOW}13.${C_NC}🖥️ Información Completa del Sistema"
    echo -e "${C_CYAN}╠══════════════════════════════════════════════╣${C_NC}"
    echo -e "  ${C_RED}88.${C_NC} ❌ Desinstalar Script   |   ${C_RED}0.${C_NC} 🚪 Salir"
    echo -e "${C_CYAN}╚══════════════════════════════════════════════╝${C_NC}"
    echo -n -e "${C_YELLOW}Seleccione una opción: ${C_NC}"
    read opcion

    case $opcion in
        1) menu_ssh ;; 2) menu_xray_proto "VMess" ;; 3) menu_xray_proto "VLESS" ;; 4) menu_xray_proto "Trojan" ;;
        5) menu_openvpn ;; 6) menu_checkuser ;; 7) menu_herramientas ;; 8) menu_puertos ;; 9) menu_dominio ;;
        10) menu_bot ;; 11) menu_update ;; 12) menu_autostart ;; 13) menu_info ;; 88) uninstall_script ;; 0) clear; exit 0 ;;
        *) echo -e "\n${C_RED}[!] Opción inválida.${C_NC}"; sleep 1 ;;
    esac
done
