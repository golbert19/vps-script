#!/bin/bash
# ==========================================
# Módulo: Instalador BHTTP Proxy (Nativo con Espejos)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}       INSTALADOR BHTTP CUSTOM PROXY            ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}NOTA: Los puertos 80, 443, 8080 y 8181 ya están en uso.${C_NC}"
read -p "Ingresa un puerto libre para BHTTP [Por defecto 8180]: " INPUT_PORT
BHTTP_PORT=${INPUT_PORT:-8180}

mkdir -p /etc/vps-manager
echo "$BHTTP_PORT" > /etc/vps-manager/bhttp_port

echo -e "${C_YELLOW}[+] Preparando entorno BHTTP...${C_NC}"
pkill -f bhttp-server >/dev/null 2>&1
fuser -k ${BHTTP_PORT}/tcp >/dev/null 2>&1

mkdir -p /etc/vps-manager/bhttp
cd /etc/vps-manager/bhttp || exit 1
rm -f bhttp-server

echo -e "${C_YELLOW}[+] Descargando binario BHTTP...${C_NC}"
# 1. Intenta descargar desde tu repositorio
wget -qO bhttp-server "https://raw.githubusercontent.com/golbert19/vps-script/main/core/bhttp-server"

# 2. Si no lo tienes subido, busca en espejos de la comunidad
if [ "$(stat -c%s "bhttp-server" 2>/dev/null || echo 0)" -lt 1000 ]; then
    echo -e "${C_YELLOW}[!] Binario no encontrado en tu repo. Buscando en espejos externos...${C_NC}"
    URLS=(
        "https://raw.githubusercontent.com/hexpn/bhttp/main/bhttp-linux-amd64"
        "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Plugins/bhttp"
        "https://raw.githubusercontent.com/ChumoGH/ChumoGH-Script/master/BINARIOS/bhttp"
    )
    for url in "${URLS[@]}"; do
        wget -qO bhttp-server "$url"
        if [ "$(stat -c%s "bhttp-server" 2>/dev/null || echo 0)" -gt 500000 ]; then
            break
        fi
    done
fi

chmod +x bhttp-server

# Verificación final
if [ "$(stat -c%s "bhttp-server" 2>/dev/null || echo 0)" -lt 500000 ]; then
    echo -e "${C_RED}[✘] Error Crítico: No se pudo descargar el binario desde ningún servidor.${C_NC}"
    echo -e "Asegúrate de subir un binario válido llamado 'bhttp-server' a tu GitHub."
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

echo -e "${C_YELLOW}[+] Configurando Firewall...${C_NC}"
iptables -I INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT 2>/dev/null
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
