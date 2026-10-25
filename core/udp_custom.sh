#!/bin/bash
# ==========================================
# Módulo: UDP Custom Nativo (Optimizado)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

UDP_DIR="/etc/vps-manager/udp"
mkdir -p "$UDP_DIR"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}       INSTALADOR NATIVO UDP CUSTOM             ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

read -p "Ingresa el puerto UDP principal (Ej: 7300): " UDP_PORT
[ -z "$UDP_PORT" ] && UDP_PORT=7300

echo -e "${C_YELLOW}[+] Descargando binario y configurando servicio...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y wget iptables net-tools >/dev/null 2>&1

cd "$UDP_DIR"

# Descargar el núcleo oficial de UDP Custom directamente
wget -qO udp-custom "https://raw.githubusercontent.com/http-custom/udp-custom/main/bin/udp-custom-linux-amd64"
if [ ! -s "udp-custom" ]; then
    # Enlace de respaldo alternativo si el principal falla
    wget -qO udp-custom "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Plugins/udp-custom" 2>/dev/null
fi

chmod +x udp-custom

# Configurar reglas de Iptables para abrir el puerto UDP
iptables -I INPUT -p udp --dport $UDP_PORT -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null

# Crear servicio Systemd robusto
cat << EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Server by Golbert
After=network.target

[Service]
User=root
WorkingDirectory=$UDP_DIR
ExecStart=$UDP_DIR/udp-custom server -port $UDP_PORT
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
echo -e "${C_GREEN}[✔] ¡UDP Custom instalado y activo con éxito!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 Host / IP : $IP_VPS"
echo -e " 🎯 Puerto UDP: $UDP_PORT"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presione Enter para regresar al menú..."
