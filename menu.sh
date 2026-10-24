#!/bin/bash

ORANGE='\033[38;5;208m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GREEN='\033[1;32m'
RED='\033[1;31m'
GRAY='\033[1;30m'
BG_RED='\033[41;1;37m'
NC='\033[0m'

DIR="/etc/vps-manager"
DB_USERS="$DIR/users.db"
DB_VMESS="$DIR/vmess.db"
DB_VLESS="$DIR/vless.db"
DB_TROJAN="$DIR/trojan.db"
DB_SS="$DIR/ss.db"
XRAY_CFG="/usr/local/etc/xray/config.json"

mkdir -p "$DIR"
touch "$DB_USERS" "$DB_VMESS" "$DB_VLESS" "$DB_TROJAN" "$DB_SS"

dibujar_barra() {
    local porcentaje=$1
    local entero=${porcentaje%.*}
    [[ -z "$entero" ]] && entero=0
    local llenos=$(( entero * 20 / 100 ))
    [[ $llenos -gt 20 ]] && llenos=20 [[$llenos -lt 0 ]] && llenos=0
    local vacios=$(( 20 - llenos ))

    local barra="${CYAN}"
    for ((i=0; i<llenos; i++)); do barra+="|"; done
    barra+="${GRAY}"
    for ((i=0; i<vacios; i++)); do barra+="|"; done
    barra+="${NC}"
    echo -ne "$barra"
}

estado_servicio() {
    if systemctl is-active --quiet "$1"; then
        echo -ne "${CYAN}[${GREEN}ON${CYAN}]${NC}"
    else
        echo -ne "${CYAN}[${RED}OFF${CYAN}]${NC}"
    fi
}

menu_banner() {
    clear
    echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${ORANGE}│${WHITE}           CONFIGURAR BANNER SSH / DROPBEAR      ${ORANGE}│${NC}"
    echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}Banner actual (/etc/issue.net):${NC}"
    cat /etc/issue.net 2>/dev/null || echo "Sin banner configurado."
    echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
    echo -e "Escribe tu nuevo banner personalizado."
    echo -e "Para finalizar y guardar, presiona Enter y escribe ${GREEN}EOF${NC} en una nueva línea:"
    echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
    
    cat << 'EOF' > /etc/issue.net
===================================================
             ⚡ GOLBERT VPS - PREMIUM ⚡             
===================================================
- Uso autorizado solo para clientes registrados.
- Prohibido el Torrent y abusos del servidor.
===================================================
EOF

    if ! grep -q "Banner /etc/issue.net" /etc/ssh/sshd_config; then
        echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
        systemctl restart ssh
    fi
    
    if grep -q "DROPBEAR_BANNER" /etc/default/dropbear; then
        sed -i 's|DROPBEAR_BANNER=.*|DROPBEAR_BANNER="/etc/issue.net"|g' /etc/default/dropbear
    else
        echo 'DROPBEAR_BANNER="/etc/issue.net"' >> /etc/default/dropbear
    fi
    systemctl restart dropbear

    echo -e "${GREEN}[✔] Banner configurado y aplicado correctamente.${NC}"
    sleep 2
}

menu_ssh() {
    clear
    IP=$(curl -s --max-time 3 ipv4.icanhazip.com || hostname -I | awk '{print $1}')
    DOMAIN=$(cat "$DIR/domain" 2>/dev/null \vert{}\vert{} echo "$IP")
    NS_DOMAIN=$(cat "$DIR/ns_domain" 2>/dev/null || echo "Sin configurar")
    PUB_KEY=$(cat "$DIR/server.pub" 2>/dev/null || echo "No generada")

    echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${ORANGE}│${WHITE}              GESTIÓN SSH & TÚNELES              ${ORANGE}│${NC}"
    echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}[01]${WHITE} Crear Usuario SSH / Dropbear / Proxy / DNSTT"
    echo -e "${CYAN}[02]${WHITE} Eliminar Usuario SSH"
    echo -e "${CYAN}[03]${WHITE} Renovar Usuario SSH"
    echo -e "${CYAN}[04]${WHITE} Ver Usuarios Conectados"
    echo -e "${CYAN}[0]${WHITE} Volver al Panel Principal"
    echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
    read -p "Seleccione una opción: " subop

    case $subop in
        1|01)
            clear
            echo -e "${CYAN}=== CREAR CUENTA MULTIPROTOCOLO ===${NC}"
            read -p "Usuario: " user
            if [[ -z "$user" ]] \vert{}\vert{} id "$user" &>/dev/null; then
                echo -e "${RED}Usuario inválido o ya existente.${NC}"; sleep 2; return
            fi
            read -p "Contraseña: " pass
            read -p "Días de duración: " dias
            read -p "Límite de conexiones: " limite

            exp_date=$(date -d "+$dias days" +"%Y-%m-%d")
            useradd -e "$exp_date" -M -s /bin/false "$user"
            echo "$user:$pass" | chpasswd
            echo "$user|$pass\vert{}$exp_date|$limite" >> "$DB_USERS"

            if [[ -f /etc/hysteria/config.yaml ]]; then
                systemctl restart hysteria &>/dev/null
            fi

            clear
            echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
            echo -e "${ORANGE}│${GREEN}            CUENTA SSH CREADA CON ÉXITO          ${ORANGE}│${NC}"
            echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
            echo -e "${CYAN}IP / Dominio   :${WHITE} $IP / $DOMAIN"
            echo -e "${CYAN}Usuario        :${WHITE}$user"
            echo -e "${CYAN}Contraseña     :${WHITE}$pass"
            echo -e "${CYAN}Puerto SSH     :${WHITE} 22"
            echo -e "${CYAN}Dropbear Ports :${WHITE} 143, 109"
            echo -e "${CYAN}Proxy / WS     :${WHITE} 80, 8080 (BHTTP), 8180 (HCR)"
            echo -e "${CYAN}TLS / SSL      :${WHITE} 443"
            echo -e "${CYAN}ZIVPN UDP      :${WHITE} 20000-29999"
            echo -e "${CYAN}UDPGW BadVPN   :${WHITE} 7300 (UDP Custom 1-65535)"
            echo -e "${CYAN}Nameserver NS  :${WHITE}$NS_DOMAIN"
            echo -e "${CYAN}Public Key DNS :${WHITE}$PUB_KEY"
            echo -e "${CYAN}Expiración     :${WHITE} $exp_date (Límite: $limite)"
            echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
            echo -e "${CYAN}Payload HTTP Proxy -> SSH:${NC}"
            echo -e "${WHITE}GET / HTTP/1.1[crlf]Host: $DOMAIN[crlf]Upgrade: websocket[crlf][crlf]${NC}"
            echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
            read -p "Presione ENTER para continuar..."
            ;;
        2|02)
            read -p "Usuario a eliminar: " user
            pkill -u "$user" 2>/dev/null
            userdel -f "$user" 2>/dev/null
            sed -i "/^$user\b/d" "$DB_USERS"
            echo -e "${GREEN}Usuario eliminado.${NC}"; sleep 2
            ;;
        3|03)
            read -p "Usuario a renovar: " user
            if ! id "$user" &>/dev/null; then
                echo -e "${RED}El usuario no existe.${NC}"; sleep 2; return
            fi
            read -p "Nuevos días de vigencia: " dias
            exp_date=$(date -d "+$dias days" +"%Y-%m-%d")
            chage -E "$exp_date" "$user"
            awk -F'|' -v u="$user" -v e="$exp_date" 'BEGIN{OFS="|"} $1==u{$3=e}1' "$DB_USERS" > /tmp/db_u && mv /tmp/db_u "$DB_USERS"
            echo -e "${GREEN}Usuario renovado hasta $exp_date.${NC}"; sleep 2
#!/bin/bash

ORANGE='\033[38;5;208m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GREEN='\033[1;32m'
RED='\033[1;31m'
GRAY='\033[1;30m'
BG_RED='\033[41;1;37m'
NC='\033[0m'

DIR="/etc/vps-manager"
DB_USERS="$DIR/users.db"
DB_VMESS="$DIR/vmess.db"
DB_VLESS="$DIR/vless.db"
DB_TROJAN="$DIR/trojan.db"
DB_SS="$DIR/ss.db"
XRAY_CFG="/usr/local/etc/xray/config.json"

mkdir -p "$DIR"
touch "$DB_USERS" "$DB_VMESS" "$DB_VLESS" "$DB_TROJAN" "$DB_SS"

dibujar_barra() {
    local porcentaje=$1
    local entero=${porcentaje%.*}
    [[ -z "$entero" ]] && entero=0
    local llenos=$(( entero * 20 / 100 ))
    [[ $llenos -gt 20 ]] && llenos=20
    [[ $llenos -lt 0 ]] && llenos=0
    local vacios=$(( 20 - llenos ))

    local barra="${CYAN}"
    for ((i=0; i<llenos; i++)); do barra+="|"; done
    barra+="${GRAY}"
    for ((i=0; i<vacios; i++)); do barra+="|"; done
    barra+="${NC}"
    echo -ne "$barra"
}

estado_servicio() {
    if systemctl is-active --quiet "$1"; then
        echo -ne "${CYAN}[${GREEN}ON${CYAN}]${NC}"
    else
        echo -ne "${CYAN}[${RED}OFF${CYAN}]${NC}"
    fi
}

menu_banner() {
    clear
    echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${ORANGE}│${WHITE}           CONFIGURAR BANNER SSH / DROPBEAR      ${ORANGE}│${NC}"
    echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}Banner actual (/etc/issue.net):${NC}"
    cat /etc/issue.net 2>/dev/null || echo "Sin banner configurado."
    echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
    echo -e "Escribe tu nuevo banner personalizado."
    echo -e "Para finalizar y guardar, presiona Enter y escribe ${GREEN}EOF${NC} en una nueva línea:"
    echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
    
    cat << 'EOF' > /etc/issue.net
===================================================
             ⚡ GOLBERT VPS - PREMIUM ⚡             
===================================================
- Uso autorizado solo para clientes registrados.
- Prohibido el Torrent y abusos del servidor.
===================================================
EOF

    if ! grep -q "Banner /etc/issue.net" /etc/ssh/sshd_config; then
        echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
        systemctl restart ssh
    fi
    
    if grep -q "DROPBEAR_BANNER" /etc/default/dropbear; then
        sed -i 's|DROPBEAR_BANNER=.*|DROPBEAR_BANNER="/etc/issue.net"|g' /etc/default/dropbear
    else
        echo 'DROPBEAR_BANNER="/etc/issue.net"' >> /etc/default/dropbear
    fi
    systemctl restart dropbear

    echo -e "${GREEN}[✔] Banner configurado y aplicado correctamente.${NC}"
    sleep 2
}

menu_ssh() {
    clear
    IP=$(curl -s --max-time 3 ipv4.icanhazip.com || hostname -I | awk '{print $1}')
    DOMAIN=$(cat "$DIR/domain" 2>/dev/null || echo "$IP")
    NS_DOMAIN=$(cat "$DIR/ns_domain" 2>/dev/null || echo "Sin configurar")
    PUB_KEY=$(cat "$DIR/server.pub" 2>/dev/null || echo "No generada")

    echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${ORANGE}│${WHITE}              GESTIÓN SSH & TÚNELES              ${ORANGE}│${NC}"
    echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}[01]${WHITE} Crear Usuario SSH / Dropbear / Proxy / DNSTT"
    echo -e "${CYAN}[02]${WHITE} Eliminar Usuario SSH"
    echo -e "${CYAN}[03]${WHITE} Renovar Usuario SSH"
    echo -e "${CYAN}[04]${WHITE} Ver Usuarios Conectados"
    echo -e "${CYAN}[0] ${WHITE} Volver al Panel Principal"
    echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
    read -p "Seleccione una opción: " subop

    case $subop in
        1|01)
            clear
            echo -e "${CYAN}=== CREAR CUENTA MULTIPROTOCOLO ===${NC}"
            read -p "Usuario: " user
            if [[ -z "$user" ]] || id "$user" &>/dev/null; then
                echo -e "${RED}Usuario inválido o ya existente.${NC}"; sleep 2; return
            fi
            read -p "Contraseña: " pass
            read -p "Días de duración: " dias
            read -p "Límite de conexiones: " limite

            exp_date=$(date -d "+$dias days" +"%Y-%m-%d")
            useradd -e "$exp_date" -M -s /bin/false "$user"
            echo "$user:$pass" | chpasswd
            echo "$user|$pass|$exp_date|$limite" >> "$DB_USERS"

            if [[ -f /etc/hysteria/config.yaml ]]; then
                systemctl restart hysteria &>/dev/null
            fi

            clear
            echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
            echo -e "${ORANGE}│${GREEN}            CUENTA SSH CREADA CON ÉXITO          ${ORANGE}│${NC}"
            echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
            echo -e "${CYAN}IP / Dominio   :${WHITE} $IP / $DOMAIN"
            echo -e "${CYAN}Usuario        :${WHITE} $user"
            echo -e "${CYAN}Contraseña     :${WHITE} $pass"
            echo -e "${CYAN}Puerto SSH     :${WHITE} 22"
            echo -e "${CYAN}Dropbear Ports :${WHITE} 143, 109"
            echo -e "${CYAN}Proxy / WS     :${WHITE} 80, 8080 (BHTTP), 8180 (HCR)"
            echo -e "${CYAN}TLS / SSL      :${WHITE} 443"
            echo -e "${CYAN}ZIVPN UDP      :${WHITE} 20000-29999"
            echo -e "${CYAN}UDPGW BadVPN   :${WHITE} 7300 (UDP Custom 1-65535)"
            echo -e "${CYAN}Nameserver NS  :${WHITE} $NS_DOMAIN"
            echo -e "${CYAN}Public Key DNS :${WHITE} $PUB_KEY"
            echo -e "${CYAN}Expiración     :${WHITE} $exp_date (Límite: $limite)"
            echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
            echo -e "${CYAN}Payload HTTP Proxy -> SSH:${NC}"
            echo -e "${WHITE}GET / HTTP/1.1[crlf]Host: $DOMAIN[crlf]Upgrade: websocket[crlf][crlf]${NC}"
            echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
            read -p "Presione ENTER para continuar..."
            ;;
        2|02)
            read -p "Usuario a eliminar: " user
            pkill -u "$user" 2>/dev/null
            userdel -f "$user" 2>/dev/null
            sed -i "/^$user\b/d" "$DB_USERS"
            echo -e "${GREEN}Usuario eliminado.${NC}"; sleep 2
            ;;
        3|03)
            read -p "Usuario a renovar: " user
            if ! id "$user" &>/dev/null; then
                echo -e "${RED}El usuario no existe.${NC}"; sleep 2; return
            fi
            read -p "Nuevos días de vigencia: " dias
            exp_date=$(date -d "+$dias days" +"%Y-%m-%d")
            chage -E "$exp_date" "$user"
            awk -F'|' -v u="$user" -v e="$exp_date" 'BEGIN{OFS="|"} $1==u{$3=e}1' "$DB_USERS" > /tmp/db_u && mv /tmp/db_u "$DB_USERS"
            echo -e "${GREEN}Usuario renovado hasta $exp_date.${NC}"; sleep 2
            ;;
        4|04)
            clear
            echo -e "${CYAN}USUARIO            CONEXIONES      EXPIRACIÓN${NC}"
            echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
            while IFS='|' read -r u p e l; do
                [[ -z "$u" ]] && continue
                c=$(ps -u "$u" 2>/dev/null | grep sshd | wc -l)
                printf "${WHITE}%-18s %-15s %-15s${NC}\n" "$u" "$c/$l" "$e"
            done < "$DB_USERS"
            echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
            read -p "Presione ENTER para volver..."
            ;;
    esac
}

menu_xray_proto() {
    local proto=$1
    local db_file=$2
    clear
    DOMAIN=$(cat "$DIR/domain" 2>/dev/null || curl -s --max-time 3 ipv4.icanhazip.com)
    echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${ORANGE}│${WHITE}              GESTIÓN PROTOCOLO ${proto^^}            ${ORANGE}│${NC}"
    echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}[01]${WHITE} Crear cuenta ${proto^^}"
    echo -e "${CYAN}[02]${WHITE} Eliminar cuenta ${proto^^}"
    echo -e "${CYAN}[0] ${WHITE} Volver"
    echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
    read -p "Seleccione una opción: " xop

    if [[ "$xop" == "1" || "$xop" == "01" ]]; then
        read -p "Alias / Usuario: " user
        read -p "Días de duración: " dias
        read -p "Seleccionar Puerto (80 NoTLS / 443 TLS): " puerto_xray
        [[ -z "$puerto_xray" ]] && puerto_xray="80"

        uuid=$(cat /proc/sys/kernel/random/uuid)
        exp_date=$(date -d "+$dias days" +"%Y-%m-%d")
        echo "$user|$uuid|$exp_date" >> "$db_file"

        if [[ -f "$XRAY_CFG" ]]; then
            jq --arg uuid "$uuid" --arg email "$user" \
               '.inbounds[0].settings.clients += [{"id": $uuid, "alterId": 0, "email": $email}]' \
               "$XRAY_CFG" > /tmp/xray.json 2>/dev/null && mv /tmp/xray.json "$XRAY_CFG"
            systemctl restart xray 2>/dev/null
        fi

        path_ws="/vmess"
        [[ "$puerto_xray" == "443" ]] && path_ws="/vmess-tls"

        json_vmess=$(cat <<EOF
{
  "v": "2",
  "ps": "$user",
  "add": "$DOMAIN",
  "port": "$puerto_xray",
  "id": "$uuid",
  "aid": "0",
  "net": "ws",
  "type": "none",
  "host": "$DOMAIN",
  "path": "$path_ws",
  "tls": "$([[ "$puerto_xray" == "443" ]] && echo "tls" || echo "none")"
}
EOF
)
        link_vmess="vmess://$(echo -n "$json_vmess" | base64 -w 0)"

        clear
        echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
        echo -e "${ORANGE}│${GREEN}            CUENTA ${proto^^} CREADA CON ÉXITO        ${ORANGE}│${NC}"
        echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
        echo -e "${CYAN}Usuario :${WHITE} $user"
        echo -e "${CYAN}UUID    :${WHITE} $uuid"
        echo -e "${CYAN}Host    :${WHITE} $DOMAIN"
        echo -e "${CYAN}Puerto  :${WHITE} $puerto_xray (WS $path_ws)"
        echo -e "${CYAN}Expira  :${WHITE} $exp_date"
        echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
        echo -e "${CYAN}Enlace VMess:${NC}"
        echo -e "${WHITE}$link_vmess${NC}"
        echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
        read -p "Presione ENTER para volver..."
    elif [[ "$xop" == "2" || "$xop" == "02" ]]; then
        read -p "Usuario a eliminar: " user
        sed -i "/^$user\|/d" "$db_file"
        if [[ -f "$XRAY_CFG" ]]; then
            jq --arg email "$user" 'del(.inbounds[0].settings.clients[] | select(.email == $email))' \
               "$XRAY_CFG" > /tmp/xray.json 2>/dev/null && mv /tmp/xray.json "$XRAY_CFG"
            systemctl restart xray 2>/dev/null
        fi
        echo -e "${GREEN}Usuario eliminado.${NC}"; sleep 2
    fi
}

menu_checkuser() {
    clear
    echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${ORANGE}│${WHITE}              CHECKUSER & LIMITADOR              ${ORANGE}│${NC}"
    echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}Estado Limitador :${WHITE} $(systemctl is-active vps-limiter)"
    echo -e "${CYAN}Últimos eventos  :${NC}"
    tail -n 10 /var/log/vps-limiter.log 2>/dev/null || echo -e "${WHITE}Sin registros recientes.${NC}"
    echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
    read -p "Presione ENTER para volver..."
}

menu_telegram() {
    clear
    echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${ORANGE}│${WHITE}           CONFIGURACIÓN BOT TELEGRAM            ${ORANGE}│${NC}"
    echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
    read -p "Ingrese su Bot Token: " token
    read -p "Ingrese su Chat ID (Admin): " chatid
    echo "$token" > "$DIR/bot_token"
    echo "$chatid" > "$DIR/chat_id"
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
         -d chat_id="${chatid}" \
         -d text="✅ Panel de Control VPS V4.5 LTS vinculado correctamente." >/dev/null
    echo -e "${GREEN}Notificaciones de Telegram vinculadas.${NC}"
    sleep 2
}

menu_panel_vps() {
    clear
    echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${ORANGE}│${WHITE}            AJUSTES DEL SERVIDOR VPS             ${ORANGE}│${NC}"
    echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}[01]${WHITE} Configurar Dominio y Nameserver (SlowDNS)"
    echo -e "${CYAN}[02]${WHITE} Configurar Banner SSH / Dropbear"
    echo -e "${CYAN}[03]${WHITE} Actualizar Script desde GitHub (Panel/Proxy)"
    echo -e "${CYAN}[04]${WHITE} Reiniciar Todos los Servicios"
    echo -e "${CYAN}[05]${WHITE} Limpiar Memoria RAM y Caché"
    echo -e "${CYAN}[06]${WHITE} Reiniciar VPS (Reboot)"
    echo -e "${CYAN}[0] ${WHITE} Volver"
    echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
    read -p "Seleccione una opción: " pop
    case $pop in
        1|01)
            read -p "Dominio principal: " dom
            read -p "Nameserver (NS): " ns
            echo "$dom" > "$DIR/domain"
            echo "$ns" > "$DIR/ns_domain"
            cat <<EOF > /etc/systemd/system/dnstt.service
[Unit]
Description=DNSTT SlowDNS Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/dnstt-server -udp :5300 -privkey-file /etc/vps-manager/server.key ${ns} 127.0.0.1:22
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
            systemctl daemon-reload
            systemctl restart dnstt
            echo -e "${GREEN}Dominios y SlowDNS actualizados.${NC}"; sleep 2
            ;;
        2|02)
            menu_banner
            ;;
        3|03)
            echo -e "${CYAN}[*] Actualizando archivos desde GitHub...${NC}"
            REPO_URL="https://raw.githubusercontent.com/golbert19/vps-script/main"
            wget -O "$DIR/proxy.py" "$REPO_URL/proxy.py" &>/dev/null
            wget -O "$DIR/limiter.sh" "$REPO_URL/limiter.sh" &>/dev/null
            wget -O /usr/local/bin/menu "$REPO_URL/menu.sh" &>/dev/null
            chmod +x "$DIR/proxy.py" "$DIR/limiter.sh" /usr/local/bin/menu
            systemctl restart proxy-http-80 proxy-http-8080 proxy-http-8180 vps-limiter &>/dev/null
            echo -e "${GREEN}[✔] ¡Script actualizado con éxito!${NC}"
            sleep 2
            ;;
        4|04)
            systemctl restart ssh dropbear stunnel4 proxy-http-80 proxy-http-8080 proxy-http-8180 dnstt xray hysteria zivpn udpgw vps-limiter 2>/dev/null
            echo -e "${GREEN}Servicios reiniciados correctamente.${NC}"; sleep 2
            ;;
        5|05)
            sync; echo 3 > /proc/sys/vm/drop_caches
            echo -e "${GREEN}Memoria RAM optimizada.${NC}"; sleep 2
            ;;
        6|06)
            reboot
            ;;
    esac
}

while true; do
    clear

    OS_NAME=$(grep -w "PRETTY_NAME" /etc/os-release | cut -d= -f2 | tr -d '"')
    UPTIME_STR=$(uptime -p | sed 's/^up //')
    IP_ADDR=$(curl -s --max-time 2 ipv4.icanhazip.com || hostname -I | awk '{print $1}')
    DOM_ADDR=$(cat "$DIR/domain" 2>/dev/null || echo "$IP_ADDR")

    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
    DISK_FREE=$(df -h / | awk 'NR==2 {print $4}')

    CPU_CORES=$(nproc)
    CPU_USAGE=$(top -bn1 | awk '/Cpu\(s\)/ {printf "%.1f", 100 - $8}')
    [[ -z "$CPU_USAGE" ]] && CPU_USAGE="5.0"
    BAR_CPU=$(dibujar_barra "$CPU_USAGE")

    RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
    RAM_FREE=$(free -m | awk '/Mem:/ {print $4}')
    RAM_PCT=$(( RAM_USED * 100 / (RAM_TOTAL > 0 ? RAM_TOTAL : 1) ))
    BAR_RAM=$(dibujar_barra "$RAM_PCT")

    ST_XRAY=$(estado_servicio xray)
    ST_HAPROXY=$(estado_servicio proxy-http-80)
    ST_SSH=$(estado_servicio ssh)

    CNT_SSH=$(grep -c '|' "$DB_USERS" 2>/dev/null || echo 0)
    CNT_VM=$(grep -c '|' "$DB_VMESS" 2>/dev/null || echo 0)
    CNT_VL=$(grep -c '|' "$DB_VLESS" 2>/dev/null || echo 0)
    CNT_TR=$(grep -c '|' "$DB_TROJAN" 2>/dev/null || echo 0)
    CNT_SS=$(grep -c '|' "$DB_SS" 2>/dev/null || echo 0)

    ON_SSH=$(ps aux | grep "\[priv\]" | wc -l)
    ON_VMESS=0
    ON_VLESS=0

    echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${ORANGE}│            🦅  ${WHITE}PANEL DE CONTROL VPS${ORANGE}  🦅           │${NC}"
    echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}OS      :${WHITE} $OS_NAME${NC}"
    echo -e "${CYAN}UPTIME  :${WHITE} $UPTIME_STR${NC}"
    echo -e "${CYAN}IP/DOM  :${WHITE} $IP_ADDR / $DOM_ADDR${NC}"
    echo -e "${CYAN}DISCO   :${WHITE} Total ${DISK_TOTAL}    Uso ${DISK_USED}    Libre ${DISK_FREE}${NC}"
    echo -e "${CYAN}CPU     :${WHITE} [${BAR_CPU} ${WHITE}${CPU_USAGE}%]  Cores: ${CPU_CORES}${NC}"
    echo -e "${CYAN}RAM     :${WHITE} [${BAR_RAM} ${WHITE}${RAM_USED}M/${RAM_TOTAL}M] Libre: ${RAM_FREE}M${NC}"
    echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
    echo -e "${WHITE}SERVICIOS: ${CYAN}XRAY:${ST_XRAY}  ${CYAN}PROXY:${ST_HAPROXY}  ${CYAN}SSH:${ST_SSH}${NC}"
    echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}CUENTAS  : SSH:${CNT_SSH}  VM:${CNT_VM}  VL:${CNT_VL}  TR:${CNT_TR}  SS:${CNT_SS}${NC}"
    echo -e "${CYAN}ESTADO   : ON SSH:${ON_SSH}  VMESS:${ON_VMESS}  VLESS:${ON_VLESS}${NC}"
    echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}[01]${WHITE} SSH & OVPN        ${CYAN}[06]${WHITE} TELEGRAM NOTIFY${NC}"
    echo -e "${CYAN}[02]${WHITE} VMESS             ${CYAN}[07]${WHITE} MENÚ BOT SERVER${NC}"
    echo -e "${CYAN}[03]${WHITE} VLESS             ${CYAN}[08]${WHITE} MENÚ EXTRAS${NC}"
    echo -e "${CYAN}[04]${WHITE} TROJAN            ${CYAN}[09]${WHITE} PANEL VPS${NC}"
    echo -e "${CYAN}[05]${WHITE} CHECKUSER         ${CYAN}[x] ${WHITE} SALIR${NC}"
    echo ""
    echo -e "   ${BG_RED}           VERSIÓN SCRIPT: V4.5 LTS            ${NC}"
    echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
    echo -ne "${WHITE}Seleccione una opción: ${NC}"
    read opcion

    case $opcion in
        1|01) menu_ssh ;;
        2|02) menu_xray_proto "vmess" "$DB_VMESS" ;;
        3|03) menu_xray_proto "vless" "$DB_VLESS" ;;
        4|04) menu_xray_proto "trojan" "$DB_TROJAN" ;;
        5|05) menu_checkuser ;;
        6|06|7|07) menu_telegram ;;
        8|08|9|09) menu_panel_vps ;;
        x|X|0) clear; exit 0 ;;
        *) echo -e "\n${RED}Opción inválida${NC}"; sleep 1 ;;
    esac
done
