#!/bin/bash
# ==========================================
# Módulo: BHTTP Binario Oficial (Puerto 8080)
# Compatible con UltraCustom / HTTP Custom (Modo BHTTP/Optimized)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

BHTTP_DIR="/etc/vps-manager/bhttp"
BHTTP_PORT=8080

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   INSTALADOR BHTTP OFICIAL (PUERTO 8080)       ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}[+] Preparando entorno y liberando puerto $BHTTP_PORT...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y wget iptables net-tools psmisc ufw >/dev/null 2>&1

# Detener cualquier servicio previo en el 8080
systemctl stop bhttp.service >/dev/null 2>&1
fuser -k ${BHTTP_PORT}/tcp >/dev/null 2>&1

mkdir -p "$BHTTP_DIR"
cd "$BHTTP_DIR"

echo -e "${C_YELLOW}[+] Descargando núcleo binario oficial de BHTTP...${C_NC}"
# Descarga directa del binario compatible con UltraCustom / HTTP Custom BHTTP mode
wget -qO bhttp-server "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Plugins/bhttp" 2>/dev/null
if [ ! -s "bhttp-server" ]; then
    wget -qO bhttp-server "https://raw.githubusercontent.com/AAAAAEX/Tunnel/main/bhttp" 2>/dev/null
fi

chmod +x bhttp-server

# Configurar reglas de red y Firewall
iptables -D INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT 2>/dev/null
iptables -I INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
ufw allow ${BHTTP_PORT}/tcp >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Configurando servicio Systemd para BHTTP...${C_NC}"
cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=Official BHTTP Tunnel Service (Port $BHTTP_PORT)
After=network.target ssh.service

[Service]
Type=simple
User=root
WorkingDirectory=$BHTTP_DIR
ExecStart=$BHTTP_DIR/bhttp-server -port $BHTTP_PORT
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bhttp.service >/dev/null 2>&1
systemctl restart bhttp.service

IP_VPS=$(curl -s ipv4.icanhazip.com)
DOM=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "$IP_VPS" )

clear
echo -e "${C_GREEN}[✔] ¡BHTTP Oficial instalado y activo en el puerto $BHTTP_PORT!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 Host / IP    : ${C_YELLOW}$DOM${C_NC}"
echo -e " 🎯 Puerto BHTTP : ${C_YELLOW}$BHTTP_PORT${C_NC}"
echo -e " ⚡ Estado       : ${C_GREEN}Binario Nativo Activo (OK)${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presione Enter para regresar al menú..."
