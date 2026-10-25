#!/bin/bash
# ==========================================
# Módulo: UDP Custom Nativo (Puerto 2000)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
UDP_DIR="/etc/vps-manager/udp"
mkdir -p "$UDP_DIR"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}       INSTALADOR NATIVO UDP CUSTOM (2000)      ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

apt update -y >/dev/null 2>&1
apt install -y wget iptables net-tools >/dev/null 2>&1

cd "$UDP_DIR"

# Descargar el binario oficial de UDP Custom
wget -qO udp-custom "https://raw.githubusercontent.com/http-custom/udp-custom/main/bin/udp-custom-linux-amd64"
if [ ! -s "udp-custom" ]; then
    wget -qO udp-custom "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Plugins/udp-custom" 2>/dev/null
fi
chmod +x udp-custom

# Abrir el puerto 2000 UDP en el firewall
iptables -I INPUT -p udp --dport 2000 -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null

# Crear servicio Systemd para UDP Custom en puerto 2000
cat << EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Server Port 2000
After=network.target

[Service]
User=root
WorkingDirectory=$UDP_DIR
ExecStart=$UDP_DIR/udp-custom server -port 2000
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom >/dev/null 2>&1
systemctl restart udp-custom

echo -e "${C_GREEN}[✔] ¡UDP Custom instalado y activo en el puerto 2000!${C_NC}"
read -p "Presione Enter para regresar..."
