#!/bin/bash
# ==========================================
# Módulo: Instalador BHTTP Python Proxy (Multi-Puerto)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}       INSTALADOR BHTTP PYTHON PROXY            ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}NOTA: Los puertos 80, 443, 8080 y 8181 suelen estar en uso por Nginx/Web.${C_NC}"
echo -e "Si ya unificaste puertos, usa un puerto libre como ${C_GREEN}8180${C_NC}."
read -p "Ingresa el puerto para BHTTP [Por defecto 8180]: " INPUT_PORT
BHTTP_PORT=${INPUT_PORT:-8180}

mkdir -p /etc/vps-manager
echo "$BHTTP_PORT" > /etc/vps-manager/bhttp_port

echo -e "${C_YELLOW}[+] Preparando entorno y librerías Python...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y python3 python3-pip iptables net-tools psmisc ufw >/dev/null 2>&1

systemctl stop bhttp.service >/dev/null 2>&1
fuser -k ${BHTTP_PORT}/tcp >/dev/null 2>&1

mkdir -p /etc/vps-manager/bhttp
cd /etc/vps-manager/bhttp || exit 1

echo -e "${C_YELLOW}[+] Descargando módulo central BHTTP.py...${C_NC}"
# Reemplaza la URL si tu archivo en GitHub tiene otro nombre (BHTTP.py)
wget -qO BHTTP.py "https://raw.githubusercontent.com/golbert19/vps-script/main/core/BHTTP.py"

if [ ! -f "BHTTP.py" ] || [ ! -s "BHTTP.py" ]; then
    echo -e "${C_RED}[✘] Error Crítico: No se pudo descargar BHTTP.py desde el repositorio.${C_NC}"
    read -p "Presione Enter para regresar..."
    exit 1
fi

chmod +x BHTTP.py

echo -e "${C_YELLOW}[+] Inyectando configuración de puertos dinámicos...${C_NC}"
# Remplazamos el puerto por defecto (80) dentro de CONFIG en BHTTP.py por el puerto elegido
sed -i -E "s/\"port\": 80, \"ssl\": False/\"port\": ${BHTTP_PORT}, \"ssl\": False/" BHTTP.py

echo -e "${C_YELLOW}[+] Creando servicio Systemd nativo...${C_NC}"
cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=BHTTP Python Proxy Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/vps-manager/bhttp
ExecStart=/usr/bin/python3 /etc/vps-manager/bhttp/BHTTP.py
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
    echo -e "${C_GREEN}[✔] ¡BHTTP Python Proxy instalado y operando con éxito!${C_NC}"
    echo -e " 🎯 Puerto BHTTP : ${C_YELLOW}$BHTTP_PORT${C_NC}"
else
    echo -e "${C_RED}[✘] Error al iniciar BHTTP Python Server.${C_NC}"
fi
read -p "Presione Enter para regresar..."
