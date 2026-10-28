#!/bin/bash
# ==========================================
# Módulo: Instalador BHTTP Proxy (Nativo)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}       INSTALADOR BHTTP CUSTOM PROXY            ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

# Solicitar un puerto que NO colisione con la pasarela Nginx
echo -e "${C_YELLOW}NOTA: Los puertos 80, 443, 8080 y 8181 ya están en uso.${C_NC}"
read -p "Ingresa un puerto libre para BHTTP [Por defecto 8180]: " INPUT_PORT
BHTTP_PORT=${INPUT_PORT:-8180}

echo "$BHTTP_PORT" > /etc/vps-manager/bhttp_port

echo -e "${C_YELLOW}[+] Preparando entorno BHTTP...${C_NC}"
# Matar cualquier proceso antiguo de BHTTP
pkill -f bhttp-server >/dev/null 2>&1
fuser -k ${BHTTP_PORT}/tcp >/dev/null 2>&1

mkdir -p /etc/vps-manager/bhttp
cd /etc/vps-manager/bhttp || exit 1

echo -e "${C_YELLOW}[+] Descargando binario BHTTP...${C_NC}"
# Reemplaza esta URL por el enlace real a tu binario BHTTP compilado (Linux amd64)
# Asegúrate de subir el binario 'bhttp-server' a tu carpeta 'core'
wget -qO bhttp-server "https://raw.githubusercontent.com/golbert19/vps-script/main/core/bhttp-server"
chmod +x bhttp-server

# Verificar descarga
if [ ! -s "bhttp-server" ]; then
    echo -e "${C_RED}[✘] Error: No se pudo descargar el binario bhttp-server.${C_NC}"
    read -p "Presione Enter para regresar..."
    exit 1
fi

echo -e "${C_YELLOW}[+] Creando servicio Systemd...${C_NC}"
cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=BHTTP Custom Proxy Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/vps-manager/bhttp
# Ejecutando BHTTP en el puerto seleccionado. 
# Si tu binario BHTTP usa un config.json, asegúrate de que apunte a este puerto.
ExecStart=/etc/vps-manager/bhttp/bhttp-server -port $BHTTP_PORT
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bhttp.service >/dev/null 2>&1
systemctl restart bhttp.service

# Abrir puerto en el Firewall
iptables -I INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
ufw allow ${BHTTP_PORT}/tcp >/dev/null 2>&1

clear
if systemctl is-active --quiet bhttp.service; then
    echo -e "${C_GREEN}[✔] ¡BHTTP Proxy instalado y operando con éxito!${C_NC}"
    echo -e " 🎯 Puerto BHTTP : ${C_YELLOW}$BHTTP_PORT${C_NC}"
else
    echo -e "${C_RED}[✘] Error al iniciar BHTTP Server.${C_NC}"
fi
read -p "Presione Enter para regresar..."
