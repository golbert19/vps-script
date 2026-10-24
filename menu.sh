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

    echo -e "${GREEN}[✔] Banner configurado correctamente.${NC}"
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
            echo -e "${CYAN}Expiración     :${WHITE} $exp_date (Límite: $limite)"
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
            echo -e "${GREEN}Usuario renovado.${NC}"; sleep 2
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
        [[ -z "$user" ]] && return

        uuid=$(cat /proc/sys/kernel/random/uuid)
        exp_date=$(date -d "+$dias days" +"%Y-%m-%d")
        echo "$user|$uuid|$exp_date" >> "$db_file"

        if [[ -f "$XRAY_CFG" ]]; then
            jq --arg uuid "$uuid" --arg email "$user" \
               '.inbounds[0].settings.clients += [{"id": $uuid, "alterId": 0, "email": $email}]' \
               "$XRAY_CFG" > /tmp/xray.json 2>/dev/null && mv /tmp/xray.json "$XRAY_CFG"
            systemctl restart xray 2>/dev/null
        fi

        # --- ENLACE NoTLS (Puerto 80) ---
        json_notls=$(cat <<EOF
{
  "v": "2",
  "ps": "$user [NoTLS]",
  "add": "$DOMAIN",
  "port": "80",
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
        link_notls="vmess://$(echo -n "$json_notls" | base64 -w 0)"

        # --- ENLACE TLS (Puerto 443) ---
        json_tls=$(cat <<EOF
{
  "v": "2",
  "ps": "$user [TLS]",
  "add": "$DOMAIN",
  "port": "443",
  "id": "$uuid",
  "aid": "0",
  "net": "ws",
  "type": "none",
  "host": "$DOMAIN",
  "path": "/vmess-tls",
  "tls": "tls"
}
EOF
)
        link_tls="vmess://$(echo -n "$json_tls" | base64 -w 0)"

        clear
        echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
        echo -e "${ORANGE}│${GREEN}         CUENTA ${proto^^} CREADA CON ÉXITO          ${ORANGE}│${NC}"
        echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
        echo -e "${CYAN}Usuario    :${WHITE} $user"
        echo -e "${CYAN}UUID       :${WHITE} $uuid"
        echo -e "${CYAN}Host / SNI :${WHITE} $DOMAIN"
        echo -e "${CYAN}Expira     :${WHITE} $exp_date"
        echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
        echo -e "${CYAN}🔗 Enlace VMess NoTLS (Puerto 80):${NC}"
        echo -e "${WHITE}$link_notls${NC}"
        echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
        echo -e "${CYAN}🔗 Enlace VMess TLS (Puerto 443):${NC}"
        echo -e "${WHITE}$link_tls${NC}"
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
    read -p "Presione ENTER para volver..."
}

menu_panel_vps() {
    clear
    echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${ORANGE}│${WHITE}            AJUSTES DEL SERVIDOR VPS             ${ORANGE}│${NC}"
    echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}[01]${WHITE} Configurar Dominio y Nameserver (SlowDNS)"
    echo -e "${CYAN}[02]${WHITE} Configurar Banner SSH / Dropbear"
    echo -e "${CYAN}[03]${WHITE} Reiniciar Todos los Servicios"
    echo -e "${CYAN}[04]${WHITE} Limpiar Memoria RAM y Caché"
    echo -e "${CYAN}[05]${WHITE} Reiniciar VPS (Reboot)"
    echo -e "${CYAN}[0] ${WHITE} Volver"
    echo -e "${ORANGE}───────────────────────────────────────────────────${NC}"
    read -p "Seleccione una opción: " pop
    case $pop in
        1|01)
            read -p "Dominio principal: " dom
            read -p "Nameserver (NS): " ns
            echo "$dom" > "$DIR/domain"
            echo "$ns" > "$DIR/ns_domain"
            echo -e "${GREEN}Actualizado.${NC}"; sleep 2
            ;;
        2|02) menu_banner ;;
        3|03)
            systemctl restart ssh dropbear stunnel4 proxy-http-80 proxy-http-8080 proxy-http-8180 xray zivpn udpgw vps-limiter 2>/dev/null
            echo -e "${GREEN}Servicios reiniciados.${NC}"; sleep 2
            ;;
        4|04)
            sync; echo 3 > /proc/sys/vm/drop_caches
            echo -e "${GREEN}Memoria optimizada.${NC}"; sleep 2
            ;;
        5|05) reboot ;;
    esac
}

while true; do
    clear
    OS_NAME=$(grep -w "PRETTY_NAME" /etc/os-release | cut -d= -f2 | tr -d '"')
    UPTIME_STR=$(uptime -p | sed 's/^up //')
    IP_ADDR=$(curl -s --max-time 2 ipv4.icanhazip.com || hostname -I | awk '{print $1}')
    DOM_ADDR=$(cat "$DIR/domain" 2>/dev/null || echo "$IP_ADDR")

    echo -e "${ORANGE}┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${ORANGE}│            🦅  ${WHITE}PANEL DE CONTROL VPS${ORANGE}  🦅           │${NC}"
    echo -e "${ORANGE}└─────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN}OS      :${WHITE} $OS_NAME${NC}"
    echo -e "${CYAN}IP/DOM  :${WHITE} $IP_ADDR / $DOM_ADDR${NC}"
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
        9|09) menu_panel_vps ;;
        x|X|0) clear; exit 0 ;;
        *) echo -e "\n${RED}Opción inválida${NC}"; sleep 1 ;;
    esac
done
