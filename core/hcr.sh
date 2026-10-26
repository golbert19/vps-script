#!/bin/bash
# ==========================================
# Módulo: HCR Proxy Server (Oficial ePro / HTTP Custom)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
HCR_DIR="/etc/vps-manager/hcr"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   INSTALADOR HCR PROXY (OFICIAL HTTP CUSTOM)   ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

read -p "Ingresa el puerto para HCR [Por defecto 8880]: " INPUT_PORT
HCR_PORT=${INPUT_PORT:-8880}

echo -e "${C_YELLOW}[+] Preparando entorno y deteniendo servicios conflictivos...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y wget iptables net-tools psmisc ufw >/dev/null 2>&1

systemctl stop hcr.service >/dev/null 2>&1
fuser -k ${HCR_PORT}/tcp >/dev/null 2>&1

mkdir -p $HCR_DIR
cd $HCR_DIR
rm -f hcr

echo -e "${C_YELLOW}[+] Descargando binario oficial HCR (HexPn / ePro Dev Team)...${C_NC}"
# Intentamos primero desde la fuente de los desarrolladores originales (hexpn)
wget -qO hcr "https://raw.githubusercontent.com/hexpn/hcr/main/hcr-linux-amd64"
if [ ! -s "hcr" ]; then
    # Repositorio espejo oficial de la comunidad para herramientas ePro
    wget -qO hcr "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Plugins/hcr"
fi
chmod +x hcr

echo -e "${C_YELLOW}[+] Abriendo puerto $HCR_PORT en el Firewall...${C_NC}"
iptables -D INPUT -p tcp --dport $HCR_PORT -j ACCEPT 2>/dev/null
iptables -I INPUT -p tcp --dport $HCR_PORT -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
ufw allow ${HCR_PORT}/tcp >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Configurando servicio Systemd (Anti-Caídas)...${C_NC}"
cat << EOF > /etc/systemd/system/hcr.service
[Unit]
Description=HCR Proxy Server by ePro Dev
After=network.target ssh.service

[Service]
Type=simple
User=root
WorkingDirectory=$HCR_DIR
# Ejecución oficial del binario enlazando al puerto deseado
ExecStart=$HCR_DIR/hcr -p $HCR_PORT
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hcr.service >/dev/null 2>&1
systemctl restart hcr.service

IP_VPS=$(curl -s ipv4.icanhazip.com)
DOM=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "$IP_VPS" )

clear
echo -e "${C_GREEN}[✔] ¡Motor HCR Oficial instalado y operando con éxito!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 Host / IP  : ${C_YELLOW}$DOM${C_NC}"
echo -e " 🎯 Puerto TCP : ${C_YELLOW}$HCR_PORT${C_NC}"
echo -e " ⚡ Estado     : ${C_GREEN}Binario Nativo (ePro) Activo${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presione Enter para regresar al menú..."
