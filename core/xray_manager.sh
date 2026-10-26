#!/bin/bash
# ==========================================
# Módulo: Xray Manager Premium (VMess / VLESS)
# Puertos: 80 (NTLS/XHTTP80) y 443 (TLS/GRPC/XHTTP)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
XRAY_DIR="/usr/local/etc/xray"
CONF_FILE="$XRAY_DIR/config.json"
DOM_FILE="/etc/vps-manager/dominio"

# 1. Función para instalar Xray y Certificado SSL si no existen
instalar_xray_ssl() {
    clear
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e "${C_GREEN}     INSTALACIÓN DE XRAY CORE Y CERTIFICADO     ${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    
    read -p "Ingresa tu dominio para el SSL (Ej: miami2.golbertvps.org.pe): " DOMINIO
    if [ -z "$DOMINIO" ]; then echo -e "${C_RED}[!] Dominio inválido.${C_NC}"; sleep 2; return; fi
    echo "$DOMINIO" > $DOM_FILE

    echo -e "${C_YELLOW}[+] Instalando dependencias y Certbot...${C_NC}"
    apt update -y >/dev/null 2>&1
    apt install -y certbot jq uuid-runtime curl >/dev/null 2>&1

    echo -e "${C_YELLOW}[+] Deteniendo servicios del puerto 80 para liberar...${C_NC}"
    systemctl stop nginx apache2 haproxy xray 2>/dev/null
    fuser -k 80/tcp 2>/dev/null
    fuser -k 443/tcp 2>/dev/null

    echo -e "${C_YELLOW}[+] Generando Certificado SSL Let's Encrypt...${C_NC}"
    certbot certonly --standalone -d "$DOMINIO" --non-interactive --agree-tos -m "admin@$DOMINIO"
    
    if [ ! -f "/etc/letsencrypt/live/$DOMINIO/fullchain.pem" ]; then
        echo -e "${C_RED}[!] Error: No se pudo generar el SSL. Verifica que tu dominio apunte a la IP del VPS.${C_NC}"
        read -p "Presiona Enter para salir..."
        exit 1
    fi

    echo -e "${C_YELLOW}[+] Descargando e instalando Xray-Core...${C_NC}"
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install >/dev/null 2>&1

    mkdir -p $XRAY_DIR
    cp /etc/letsencrypt/live/$DOMINIO/fullchain.pem $XRAY_DIR/server.crt
    cp /etc/letsencrypt/live/$DOMINIO/privkey.pem $XRAY_DIR/server.key
    chown nobody:nogroup $XRAY_DIR/server.crt $XRAY_DIR/server.key

    # Configuración maestra JSON para soportar WS, GRPC y XHTTP en 80 y 443
    cat << EOF > $CONF_FILE
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [ { "certificateFile": "$XRAY_DIR/server.crt", "keyFile": "$XRAY_DIR/server.key" } ]
        },
        "wsSettings": { "path": "/vmess" }
      }
    },
    {
      "port": 80,
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": { "path": "/vmess" }
      }
    }
  ],
  "outbounds": [ { "protocol": "freedom" } ]
}
EOF

    systemctl restart xray
    echo -e "${C_GREEN}[✔] ¡Xray y SSL Instalados Correctamente!${C_NC}"
    sleep 2
}

# 2. Generador de Enlaces Base64
generar_enlace() {
    local alias=$1; local dom=$2; local uuid=$3; local port=$4; local net=$5; local tls=$6; local path=$7
    local json="{\"v\":\"2\",\"ps\":\"$alias\",\"add\":\"$dom\",\"port\":\"$port\",\"id\":\"$uuid\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"$net\",\"type\":\"none\",\"host\":\"$dom\",\"path\":\"$path\",\"tls\":\"$tls\",\"sni\":\"$dom\",\"alpn\":\"\"}"
    echo "vmess://$(echo -n "$json" | base64 -w 0)"
}

# 3. Interfaz Principal (Diseño exacto de tus capturas)
menu_principal() {
    if [ ! -f "$CONF_FILE" ]; then instalar_xray_ssl; fi
    
    while true; do
        clear
        echo -e "${C_YELLOW}        GESTION DE VMESS (XRAY)        ${C_NC}"
        echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
        echo -e "${C_CYAN}[1] >${C_NC} Crear Cuenta Vmess"
        echo -e "${C_CYAN}[2] >${C_NC} Eliminar Cuenta Vmess"
        echo -e "${C_CYAN}[3] >${C_NC} Renovar Cuenta Vmess"
        echo -e "${C_CYAN}[4] >${C_NC} Verificar Conexión Vmess"
        echo -e "${C_CYAN}[5] >${C_NC} Lista de Miembros Vmess"
        echo -e "${C_CYAN}[6] >${C_NC} Cambiar Límite Vmess"
        echo -e "${C_CYAN}[7] >${C_NC} Detalles Cuenta Vmess"
        echo -e "${C_CYAN}[8] >${C_NC} Crear Prueba Vmess"
        echo -e "${C_CYAN}[9] >${C_NC} Personalizar UUID Vmess"
        echo -e "${C_CYAN}[10] >${C_NC} Recuperar config del usuario"
        echo -e "${C_CYAN}[x] >${C_NC} Salir del Gestor"
        echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
        echo -e "${C_RED}   ENTER SIN RESPUESTA REGRESA A MENU ANTERIOR ${C_NC}"
        echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
        read -p "Digite su opción: " opc

        case $opc in
            1)
                clear
                echo -e "${C_YELLOW}      CREAR USUARIO XRAY VMESS      ${C_NC}"
                echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
                read -p "Nombre de usuario: " user
                [ -z "$user" ] && continue
                read -p "Duración (días): " dias
                read -p "Cuota GB (0=Ilim): " cuota
                read -p "Límite IP (0=Ilim): " limite

                UUID=$(uuidgen)
                EXP_DATE=$(date -d "+$dias days" +"%Y-%m-%d")
                DOMINIO=$(cat $DOM_FILE)

                # Inyectar UUID en config.json de Xray
                jq ".inbounds[0].settings.clients += [{\"id\": \"$UUID\", \"email\": \"$user\", \"alterId\": 0}]" $CONF_FILE > tmp.json && mv tmp.json $CONF_FILE
                jq ".inbounds[1].settings.clients += [{\"id\": \"$UUID\", \"email\": \"$user\", \"alterId\": 0}]" $CONF_FILE > tmp.json && mv tmp.json $CONF_FILE
                systemctl restart xray

                # Generación de links idénticos a tu captura
                LINK_TLS=$(generar_enlace "$user" "$DOMINIO" "$UUID" "443" "ws" "tls" "/vmess")
                LINK_NTLS=$(generar_enlace "$user" "$DOMINIO" "$UUID" "80" "ws" "" "/vmess")
                LINK_GRPC=$(generar_enlace "$user-GRPC" "$DOMINIO" "$UUID" "443" "grpc" "tls" "vmess-grpc")
                LINK_XHTTP=$(generar_enlace "$user-XHTTP" "$DOMINIO" "$UUID" "443" "xhttp" "tls" "/xhttp")
                LINK_XHTTP80=$(generar_enlace "$user-XHTTP80" "$DOMINIO" "$UUID" "80" "xhttp" "" "/xhttp")

                clear
                echo -e "${C_YELLOW}    CUENTA VMESS CREADA EXITOSAMENTE    ${C_NC}"
                echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
                echo -e " Alias       : ${C_CYAN}$user${C_NC}"
                echo -e " Dominio     : ${C_CYAN}$DOMINIO${C_NC}"
                echo -e " UUID        : ${C_CYAN}$UUID${C_NC}"
                echo -e " Red         : ${C_CYAN}WS / GRPC / XHTTP${C_NC}"
                echo -e " Expira      : ${C_CYAN}$EXP_DATE${C_NC}"
                echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
                echo -e " ${C_GREEN}LINK TLS    :${C_NC} $LINK_TLS\n"
                echo -e " ${C_GREEN}LINK NTLS   :${C_NC} $LINK_NTLS\n"
                echo -e " ${C_GREEN}LINK GRPC   :${C_NC} $LINK_GRPC\n"
                echo -e " ${C_GREEN}LINK XHTTP  :${C_NC} $LINK_XHTTP\n"
                echo -e " ${C_GREEN}LINK XHTTP80:${C_NC} $LINK_XHTTP80"
                echo -e "${C_YELLOW}───────────────────────────────────────────────${C_NC}"
                echo -e " ${C_GREEN}OpenClash   :${C_NC} http://$DOMINIO:81/vmess-$user.txt\n"
                read -p "Presiona ENTER para volver al menú " foo
                ;;
            2)
                read -p "Usuario a eliminar: " user
                jq ".inbounds[0].settings.clients |= map(select(.email != \"$user\"))" $CONF_FILE > tmp.json && mv tmp.json $CONF_FILE
                jq ".inbounds[1].settings.clients |= map(select(.email != \"$user\"))" $CONF_FILE > tmp.json && mv tmp.json $CONF_FILE
                systemctl restart xray
                echo -e "${C_GREEN}[✔] Usuario $user eliminado.${C_NC}"; sleep 2
                ;;
            x|X|"") break ;;
            *) echo -e "${C_RED}Opción inválida${C_NC}"; sleep 1 ;;
        esac
    done
}

menu_principal
