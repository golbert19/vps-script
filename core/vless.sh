#!/bin/bash
# ==========================================
# Módulo Independiente: VLESS (XRAY)
# Puertos: 80 (NTLS) y 443 (TLS)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
XRAY_DIR="/usr/local/etc/xray"
CONF_FILE="$XRAY_DIR/config.json"
DOM_FILE="/etc/vps-manager/dominio"
LIMIT_FILE="/etc/vps-manager/limites_vless"

instalar_xray_vless() {
    clear
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e "${C_GREEN}   INSTALACIÓN DE XRAY (VLESS) Y CERTIFICADO    ${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    
    read -p "Ingresa tu dominio (Ej: centrix.golbertvps.online): " DOMINIO
    if [ -z "$DOMINIO" ]; then echo -e "${C_RED}[!] Dominio inválido.${C_NC}"; sleep 2; return; fi
    mkdir -p /etc/vps-manager
    echo "$DOMINIO" > $DOM_FILE

    echo -e "${C_YELLOW}[+] Instalando dependencias...${C_NC}"
    apt update -y >/dev/null 2>&1
    apt install -y certbot jq uuid-runtime curl iptables ufw >/dev/null 2>&1

    echo -e "${C_YELLOW}[+] Liberando puertos 80 y 443...${C_NC}"
    systemctl stop nginx apache2 haproxy xray 2>/dev/null
    fuser -k 80/tcp 2>/dev/null
    fuser -k 443/tcp 2>/dev/null

    echo -e "${C_YELLOW}[+] Generando Certificado SSL...${C_NC}"
    certbot certonly --standalone -d "$DOMINIO" --non-interactive --agree-tos -m "admin@$DOMINIO"
    
    if [ ! -f "/etc/letsencrypt/live/$DOMINIO/fullchain.pem" ]; then
        echo -e "${C_RED}[!] Error SSL. Revisa que tu IP apunte al dominio en Cloudflare.${C_NC}"
        read -p "Presiona Enter..."
        exit 1
    fi

    echo -e "${C_YELLOW}[+] Instalando núcleo Xray...${C_NC}"
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install >/dev/null 2>&1
    
    iptables -I INPUT -p tcp --dport 80 -j ACCEPT
    iptables -I INPUT -p tcp --dport 443 -j ACCEPT
    iptables-save > /etc/iptables.up.rules 2>/dev/null
    ufw allow 80/tcp >/dev/null 2>&1
    ufw allow 443/tcp >/dev/null 2>&1

    mkdir -p $XRAY_DIR
    cp /etc/letsencrypt/live/$DOMINIO/fullchain.pem $XRAY_DIR/server.crt
    cp /etc/letsencrypt/live/$DOMINIO/privkey.pem $XRAY_DIR/server.key

    # Descarga automática del config.json optimizado desde tu GitHub
    echo -e "${C_YELLOW}[+] Configurando entorno Xray idéntico...${C_NC}"
    curl -sL https://raw.githubusercontent.com/golbert19/vps-script/main/config.json -o $CONF_FILE
    
    systemctl restart xray
    echo -e "${C_GREEN}[✔] ¡Instalación VLESS completada!${C_NC}"; sleep 2
}

generar_link_vless() {
    local alias=$1 dom=$2 uuid=$3 port=$4 net=$5 tls=$6 path=$7
    echo "vless://$uuid@$dom:$port?encryption=none&security=$tls&type=$net&path=$path&host=$dom&sni=$dom#$alias"
}

menu_vless() {
    if [ ! -f "$CONF_FILE" ]; then instalar_xray_vless; fi
    
    while true; do
        clear
        echo -e "${C_YELLOW}        GESTION DE VLESS (XRAY)        ${C_NC}"
        echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
        echo -e "${C_CYAN}[1] >${C_NC} Crear Cuenta Vless"
        echo -e "${C_CYAN}[2] >${C_NC} Eliminar Cuenta Vless"
        echo -e "${C_CYAN}[3] >${C_NC} Renovar Días de Cuenta"
        echo -e "${C_CYAN}[4] >${C_NC} Bloquear / Suspender Cuenta"
        echo -e "${C_CYAN}[5] >${C_NC} Configurar Límite de Dispositivos"
        echo -e "${C_CYAN}[x] >${C_NC} Salir del Gestor"
        echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
        read -p "Digite su opción: " opc

        case $opc in
            1)
                clear
                echo -e "${C_YELLOW}      CREAR USUARIO XRAY VLESS      ${C_NC}"
                echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
                read -p "Nombre de usuario: " user
                [ -z "$user" ] && continue
                read -p "Duración (días): " dias
                
                UUID=$(uuidgen)
                EXP_DATE=$(date -d "+$dias days" +"%Y-%m-%d")
                DOM=$(cat $DOM_FILE)

                # Inyección del cliente en el config.json descargado
                jq ".inbounds[0].settings.clients += [{\"id\": \"$UUID\", \"email\": \"$user\"}]" $CONF_FILE > tmp.json && mv tmp.json $CONF_FILE
                jq ".inbounds[1].settings.clients += [{\"id\": \"$UUID\", \"email\": \"$user\"}]" $CONF_FILE > tmp.json && mv tmp.json $CONF_FILE
                systemctl restart xray

                LINK_TLS=$(generar_link_vless "$user" "$DOM" "$UUID" "443" "ws" "tls" "/vless")
                LINK_NTLS=$(generar_link_vless "$user" "$DOM" "$UUID" "80" "ws" "none" "/vless")

                clear
                echo -e "${C_YELLOW}    CUENTA VLESS CREADA EXITOSAMENTE    ${C_NC}"
                echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
                echo -e " Alias       : ${C_CYAN}$user${C_NC}"
                echo -e " Dominio     : ${C_CYAN}$DOM${C_NC}"
                echo -e " UUID        : ${C_CYAN}$UUID${C_NC}"
                echo -e " Expira      : ${C_CYAN}$EXP_DATE${C_NC}"
                echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
                echo -e "\n ${C_GREEN}LINK TLS (443) :${C_NC}\n$LINK_TLS\n"
                echo -e " ${C_GREEN}LINK NTLS (80) :${C_NC}\n$LINK_NTLS\n"
                echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
                read -p "Presiona ENTER para volver al menú " foo
                ;;
            2)
                clear
                echo -e "${C_YELLOW}     ELIMINAR USUARIO XRAY VLESS     ${C_NC}"
                echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
                read -p "Usuario a eliminar: " user
                [ -z "$user" ] && continue
                
                jq ".inbounds[0].settings.clients |= map(select(.email != \"$user\"))" $CONF_FILE > tmp.json && mv tmp.json $CONF_FILE
                jq ".inbounds[1].settings.clients |= map(select(.email != \"$user\"))" $CONF_FILE > tmp.json && mv tmp.json $CONF_FILE
                systemctl restart xray
                echo -e "${C_GREEN}[✔] Cuenta $user eliminada correctamente.${C_NC}"
                read -p "Presiona ENTER para continuar..." foo
                ;;
            3)
                clear
                echo -e "${C_YELLOW}      RENOVAR CUENTA XRAY VLESS      ${C_NC}"
                echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
                read -p "Nombre del usuario a renovar: " user
                read -p "Días a sumar: " dias_extras
                [ -z "$user" ] || [ -z "$dias_extras" ] && continue
                
                NUEVA_EXP=$(date -d "+$dias_extras days" +"%Y-%m-%d")
                echo -e "${C_GREEN}[✔] Cuenta $user renovada. Nueva vigencia estimada hasta: $NUEVA_EXP${C_NC}"
                read -p "Presiona ENTER para continuar..." foo
                ;;
            4)
                clear
                echo -e "${C_YELLOW}     BLOQUEAR / SUSPENDER USUARIO     ${C_NC}"
                echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
                read -p "Nombre del usuario a bloquear: " user
                [ -z "$user" ] && continue
                
                jq ".inbounds[0].settings.clients |= map(select(.email != \"$user\"))" $CONF_FILE > tmp.json && mv tmp.json $CONF_FILE
                jq ".inbounds[1].settings.clients |= map(select(.email != \"$user\"))" $CONF_FILE > tmp.json && mv tmp.json $CONF_FILE
                systemctl restart xray
                
                echo -e "${C_GREEN}[✔] El usuario $user ha sido bloqueado del servidor.${C_NC}"
                read -p "Presiona ENTER para continuar..." foo
                ;;
            5)
                clear
                echo -e "${C_YELLOW}      LÍMITE DE DISPOSITIVOS (IPs)      ${C_NC}"
                echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
                read -p "Nombre del usuario: " user
                read -p "Máximo de dispositivos permitidos: " max_disp
                [ -z "$user" ] || [ -z "$max_disp" ] && continue
                
                mkdir -p /etc/vps-manager
                echo "$user $max_disp" >> $LIMIT_FILE
                echo -e "${C_GREEN}[✔] Límite de $max_disp dispositivos configurado para $user.${C_NC}"
                read -p "Presiona ENTER para continuar..." foo
                ;;
            x|X|"") break ;;
        esac
    done
}

menu_vless
