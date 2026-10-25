#!/bin/bash
# ==========================================
# Módulo Maestro Xray: VMess, VLESS, Trojan
# ==========================================
PROTO=$1
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'

# 1. Instalar Xray y configurar JSON si no existe
if [ ! -f "/usr/local/bin/xray" ]; then
    clear
    echo -e "${YELLOW}[+] Instalando núcleo Xray y configurando puertos (80 y 443)...${NC}"
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install >/dev/null 2>&1
    apt update -y && apt install -y jq openssl uuid-runtime >/dev/null 2>&1
    
    # Generar Certificado SSL (Para el puerto 443)
    mkdir -p /etc/xray
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/xray/server.key -out /etc/xray/server.crt -subj "/C=PE/ST=Lima/L=Lima/O=Golbert/CN=golbertvps.online" >/dev/null 2>&1
    
    # Escribir Configuración Universal
    cat <<EOF > /usr/local/etc/xray/config.json
{
  "inbounds": [
    {
      "port": 80,
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } }
    },
    {
      "port": 443,
      "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": { "network": "ws", "security": "tls", "tlsSettings": { "certificates": [ { "certificateFile": "/etc/xray/server.crt", "keyFile": "/etc/xray/server.key" } ] }, "wsSettings": { "path": "/vless" } }
    },
    {
      "port": 2083,
      "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": { "network": "ws", "security": "tls", "tlsSettings": { "certificates": [ { "certificateFile": "/etc/xray/server.crt", "keyFile": "/etc/xray/server.key" } ] }, "wsSettings": { "path": "/trojan" } }
    }
  ],
  "outbounds": [ { "protocol": "freedom" } ]
}
EOF
    systemctl restart xray
fi

# 2. Interfaz de Gestión del Usuario
while true; do
    clear
    echo -e "${CYAN}================================================${NC}"
    echo -e "${GREEN}            GESTOR XRAY ($PROTO)                 ${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo -e "${GREEN}1) ${NC}Crear usuario $PROTO"
    echo -e "${GREEN}2) ${NC}Eliminar usuario $PROTO"
    echo -e "${GREEN}0) ${NC}Volver al Menú Principal"
    echo -e "${CYAN}================================================${NC}"
    read -p "Seleccione una opción: " opt
    case $opt in
        1)
            read -p "Nombre del usuario: " user
            UUID=$(uuidgen)
            IP_V=$(curl -s ipv4.icanhazip.com)
            DOM=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "$IP_V" )
            
            # Inyectar el usuario en la base de datos de Xray sin romper el archivo
            if [ "$PROTO" == "VMess" ]; then
                jq --arg u "$user" --arg id "$UUID" '.inbounds[0].settings.clients += [{"id": $id, "alterId": 0, "email": $u}]' /usr/local/etc/xray/config.json > tmp.json && mv tmp.json /usr/local/etc/xray/config.json
                LINK="vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"$user\",\"add\":\"$DOM\",\"port\":\"80\",\"id\":\"$UUID\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$DOM\",\"path\":\"/vmess\",\"tls\":\"\"}" | base64 -w 0)"
                PT="80 (No-TLS / WS)"
            elif [ "$PROTO" == "VLESS" ]; then
                jq --arg u "$user" --arg id "$UUID" '.inbounds[1].settings.clients += [{"id": $id, "email": $u}]' /usr/local/etc/xray/config.json > tmp.json && mv tmp.json /usr/local/etc/xray/config.json
                LINK="vless://$UUID@$DOM:443?encryption=none&security=tls&type=ws&host=$DOM&path=%2Fvless#$user"
                PT="443 (TLS / WS)"
            elif [ "$PROTO" == "Trojan" ]; then
                jq --arg u "$user" --arg pass "$UUID" '.inbounds[2].settings.clients += [{"password": $pass, "email": $u}]' /usr/local/etc/xray/config.json > tmp.json && mv tmp.json /usr/local/etc/xray/config.json
                LINK="trojan://$UUID@$DOM:2083?security=tls&type=ws&host=$DOM&path=%2Ftrojan#$user"
                PT="2083 (TLS / WS)"
            fi
            systemctl restart xray
            
            clear
            echo -e "${CYAN}================================================${NC}"
            echo -e "${GREEN}        ✅ USUARIO $PROTO CREADO ✅        ${NC}"
            echo -e "${CYAN}================================================${NC}"
            echo -e " 👤 Usuario : $user"
            echo -e " 🔑 Clave   : $UUID"
            echo -e " 🌐 Host    : $DOM"
            echo -e " 🎯 Puerto  : $PT"
            echo -e "\n📌 Link de Conexión:\n\033[1;37m$LINK\033[0m"
            echo -e "${CYAN}================================================${NC}"
            read -p "Copia el link y presiona Enter..."
            ;;
        2)
            read -p "Nombre del usuario a eliminar: " user
            if [ "$PROTO" == "VMess" ]; then jq --arg u "$user" 'del(.inbounds[0].settings.clients[] | select(.email == $u))' /usr/local/etc/xray/config.json > tmp.json && mv tmp.json /usr/local/etc/xray/config.json; fi
            if [ "$PROTO" == "VLESS" ]; then jq --arg u "$user" 'del(.inbounds[1].settings.clients[] | select(.email == $u))' /usr/local/etc/xray/config.json > tmp.json && mv tmp.json /usr/local/etc/xray/config.json; fi
            if [ "$PROTO" == "Trojan" ]; then jq --arg u "$user" 'del(.inbounds[2].settings.clients[] | select(.email == $u))' /usr/local/etc/xray/config.json > tmp.json && mv tmp.json /usr/local/etc/xray/config.json; fi
            systemctl restart xray
            echo -e "${GREEN}[✔] Usuario $user eliminado de Xray.${NC}"
            sleep 2
            ;;
        0) break ;;
        *) echo -e "${RED}[!] Inválido.${NC}"; sleep 1 ;;
    esac
done
