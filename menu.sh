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

menu_ssh() {
    clear
    IP=$(curl -s --max-time 3 ipv4.icanhazip.com || hostname -I | awk '{print $1}')
    DOMAIN=$(cat "$DIR/domain" 2>/dev/null \vert{}\vert{} echo "$IP")
    NS_DOMAIN=$(cat "$DIR/ns_domain" 2>/dev/null || echo "Sin configurar")
    PUB_KEY=$(cat "$DIR/server.pub" 2>/dev/null || echo "No generada")

    echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${ORANGE}│${WHITE}              GESTIÓN SSH & TÚNELES              ${ORANGE}│${NC}"
    echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}[01]${WHITE} Crear Usuario SSH / Proxy HTTP / SSL / DNSTT"
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

            if [[ -f /etc/hysteria/config.json ]]; then
                jq --arg auth "$pass" '.auth.config += [$auth] | .auth.config |= unique' /etc/hysteria/config.json > /tmp/hys.json 2>/dev/null && mv /tmp/hys.json /etc/hysteria/config.json
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
            echo -e "${CYAN}Proxy HTTP     :${WHITE} 80, 8080, 8989"
            echo -e "${CYAN}TLS/SSL        :${WHITE} 443"
            echo -e "${CYAN}Hysteria UDP   :${WHITE} 36712 (Obfs: golbertvps)"
            echo -e "${CYAN}UDPGW BadVPN   :${WHITE} 7300"
            echo -e "${CYAN}Nameserver NS  :${WHITE}$NS_DOMAIN"
            echo -e "${CYAN}Public Key DNS :${WHITE}$PUB_KEY"
            echo -e "${CYAN}Expiración     :${WHITE} $exp_date (Límite: $limite)"
            echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
            echo -e "${CYAN}Payload HTTP Proxy -> SSH (Custom Payload):${NC}"
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
                printf "${WHITE}\%-18s \%-15s \%-15s${NC}\n" "$u" "$c/$l" "$e"
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
    echo -e "${CYAN}[01]${WHITE} Crear cuenta${proto^^}"
    echo -e "${CYAN}[02]${WHITE} Eliminar cuenta${proto^^}"
    echo -e "${CYAN}[0]${WHITE} Volver"
    echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
    read -p "Seleccione una opción: " xop

    if [[ "$xop" == "1" \vert{}\vert{} "$xop" == "01" ]]; then
        read -p "Alias / Usuario: " user
        read -p "Días de duración: " dias
        uuid=$(cat /proc/sys/kernel/random/uuid)
        exp_date=$(date -d "+$dias days" +"%Y-%m-%d")
        echo "$user\vert{}$uuid|$exp_date" >> "$db_file"

        if [[ -f "$XRAY_CFG" ]]; then
            jq --arg uuid "$uuid" --arg email "$user" \
               '.inbounds[0].settings.clients += [{"id": $uuid, "alterId": 0, "email": $email}]' \
               "$XRAY_CFG" > /tmp/xray.json 2>/dev/null && mv /tmp/xray.json "$XRAY_CFG"
            systemctl restart xray 2>/dev/null
        fi

        json_vmess=$(cat <<EOF
{
  "v": "2",
  "ps": "$user",
  "add": "$DOMAIN",
  "port": "8880",
  "id": "$uuid",
  "aid": "0",
  "net": "ws",
  "type": "none",
  "host": "$DOMAIN",
  "path": "/vmess",
  "tls": "none"
}
EOF
)
        link_vmess="vmess://$(echo -n "$json_vmess" | base64 -w 0)"

        clear
        echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
        echo -e "${ORANGE}│${GREEN}            CUENTA${proto^^} CREADA CON ÉXITO        ${ORANGE}│${NC}"
        echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
        echo -e "${CYAN}Usuario :${WHITE}$user"
        echo -e "${CYAN}UUID    :${WHITE}$uuid"
        echo -e "${CYAN}Host    :${WHITE}$DOMAIN"
        echo -e "${CYAN}Puerto  :${WHITE} 8880 (WS /vmess)"
        echo -e "${CYAN}Expira  :${WHITE}$exp_date"
        echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
        echo -e "${CYAN}Enlace VMess:${NC}"
        echo -e "${WHITE}$link_vmess${NC}"
        echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
        read -p "Presione ENTER para volver..."
    elif [[ "$xop" == "2" \vert{}\vert{} "$xop" == "02" ]]; then
        read -p "Usuario a eliminar: " user
        sed -i "/^$user\Vert{}/d" "$db_file"
        if [[ -f "$XRAY_CFG" ]]; then
            jq --arg email "$user" 'del(.inbounds[0].settings.clients[] \vert{} select(.email == $email))' \
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
    echo -e "${CYAN}Estado Limitador :${WHITE}$(systemctl is-active vps-limiter)"
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
    echo -e "${CYAN}[02]${WHITE} Actualizar Script desde GitHub (Panel/Proxy)"
    echo -e "${CYAN}[03]${WHITE} Reiniciar Todos los Servicios"
    echo -e "${CYAN}[04]${WHITE} Limpiar Memoria RAM y Caché"
    echo -e "${CYAN}[05]${WHITE} Reiniciar VPS (Reboot)"
    echo -e "${CYAN}[0]${WHITE} Volver"
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
            echo -e "${CYAN}[*] Actualizando archivos desde GitHub...${NC}"
            REPO_URL="
