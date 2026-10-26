#!/bin/bash
# ==========================================
# Módulo: UDP Custom (Binario Oficial HTTP Custom)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
UDP_DIR="/etc/udp-custom"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}    INSTALADOR OFICIAL UDP CUSTOM (PUERTO 2000) ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}[+] Limpiando versiones de prueba (Python)...${C_NC}"
systemctl stop udp-custom >/dev/null 2>&1
systemctl disable udp-custom >/dev/null 2>&1
rm -rf /etc/vps-manager/udp
rm -f /etc/systemd/system/udp-custom.service

mkdir -p "$UDP_DIR"
cd "$UDP_DIR"

echo -e "${C_YELLOW}[+] Descargando Core Oficial de UDP Custom...${C_NC}"
# Descargamos el binario real compilado para VPS
wget -qO udp-custom "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Plugins/udp-custom"
chmod +x udp-custom

# Abrir el puerto 2000 UDP en el cortafuegos
iptables -I INPUT -p udp --dport 2000 -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null

echo -e "${C_YELLOW}[+] Creando Servicio Systemd...${C_NC}"
cat << EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Official Server
After=network.target

[Service]
User=root
WorkingDirectory=$UDP_DIR
# Ejecutamos el binario original excluyendo puertos conocidos y escuchando en el 2000
ExecStart=$UDP_DIR/udp-custom server -exclude 53,80,443 -port 2000
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom >/dev/null 2>&1
systemctl restart udp-custom

IP_VPS=$(curl -s ipv4.icanhazip.com)
clear
echo -e "${C_GREEN}[✔] ¡UDP Custom (CORE OFICIAL) instalado en el puerto 2000!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 Host / IP : $IP_VPS"
echo -e " 🎯 Puerto UDP: 2000"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presione Enter para regresar al menú..."
