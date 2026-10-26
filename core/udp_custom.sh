#!/bin/bash
# ==========================================
# Módulo: UDP Custom Oficial (Puerto 25000)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
UDP_DIR="/etc/udp-custom"
UDP_PORT="25000"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}    INSTALADOR OFICIAL UDP CUSTOM ($UDP_PORT)   ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}[+] Limpiando instalaciones previas...${C_NC}"
systemctl stop udp-custom >/dev/null 2>&1
systemctl disable udp-custom >/dev/null 2>&1
rm -rf /etc/udp-custom /etc/vps-manager/udp
rm -f /etc/systemd/system/udp-custom.service

mkdir -p "$UDP_DIR"
cd "$UDP_DIR"

echo -e "${C_YELLOW}[+] Descargando binario oficial de HTTP Custom...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y wget iptables net-tools >/dev/null 2>&1

# Descarga directa desde el creador oficial
wget -qO udp-custom "https://raw.githubusercontent.com/http-custom/udp-custom/main/bin/udp-custom-linux-amd64"
chmod +x udp-custom

# Crear archivo de configuración que exige el binario oficial
cat << EOF > config.json
{
  "listen": ":$UDP_PORT",
  "exclude": "53,80,443"
}
EOF

# Abrir el puerto en el Firewall interno de Ubuntu
iptables -I INPUT -p udp --dport $UDP_PORT -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null

echo -e "${C_YELLOW}[+] Creando Servicio Systemd...${C_NC}"
cat << EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Official Server
After=network.target

[Service]
User=root
WorkingDirectory=$UDP_DIR
ExecStart=$UDP_DIR/udp-custom server -exclude 53,80,443 -port $UDP_PORT
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
echo -e "${C_GREEN}[✔] ¡UDP Custom instalado en el puerto $UDP_PORT!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 Host / IP : $IP_VPS"
echo -e " 🎯 Puerto UDP: $UDP_PORT"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_YELLOW}⚠️ IMPORTANTE: Si usas Oracle, AWS o Google Cloud, debes abrir"
echo -e "el puerto $UDP_PORT (UDP) desde el panel web de tu proveedor.${C_NC}"
read -p "Presione Enter para regresar al menú..."
