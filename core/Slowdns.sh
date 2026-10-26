#!/bin/bash
# ==========================================
# Módulo: SlowDNS / DNSTT Nativo (SSH Port 22)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
DNS_DIR="/etc/vps-manager/slowdns"
mkdir -p "$DNS_DIR"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}    INSTALADOR SLOWDNS / DNSTT (PUERTO 53 -> 22)${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

# 1. Pedir el NS (Nameserver)
read -p "Ingresa tu subdominio NS (Ej: ns-centrix.golbertvps.online): " NS_DOMAIN
if [ -z "$NS_DOMAIN" ]; then
    echo -e "${C_RED}[!] Error: No ingresaste un NS válido.${C_NC}"
    sleep 2
    exit 1
fi
echo "$NS_DOMAIN" > /etc/vps-manager/nsdomain

echo -e "${C_YELLOW}[+] Instalando dependencias necesarias...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y wget iptables net-tools >/dev/null 2>&1

# 2. Descargar Binario DNSTT-Server
cd "$DNS_DIR"
wget -qO dnstt-server "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Plugins/dnstt-server"
chmod +x dnstt-server

# 3. Generar Llaves Privadas y Públicas
echo -e "${C_YELLOW}[+] Generando llaves criptográficas...${C_NC}"
rm -f server.key server.pub
./dnstt-server -gen key -privkey-file server.key -pubkey-file server.pub >/dev/null 2>&1
PUB_KEY=$(cat server.pub)

# 4. Configurar reglas de Firewall y liberar puerto 53
systemctl stop systemd-resolved >/dev/null 2>&1
systemctl disable systemd-resolved >/dev/null 2>&1
killall -9 dnstt-server 2>/dev/null
killall -9 named 2>/dev/null
killall -9 bind9 2>/dev/null

iptables -I INPUT -p udp --dport 53 -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null

# 5. Crear el servicio Systemd (Conectando el túnel 53 hacia el puerto SSH 22)
echo -e "${C_YELLOW}[+] Configurando túnel local hacia SSH (127.0.0.1:22)...${C_NC}"
cat << EOF > /etc/systemd/system/vps-slowdns.service
[Unit]
Description=DNSTT SlowDNS Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DNS_DIR
# El parámetro -local 127.0.0.1:22 es vital para que el SSH responda al Injector
ExecStart=$DNS_DIR/dnstt-server -udp :53 -privkey-file server.key $NS_DOMAIN 127.0.0.1:22
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vps-slowdns >/dev/null 2>&1
systemctl restart vps-slowdns

clear
echo -e "${C_GREEN}[✔] ¡SlowDNS (DNSTT) instalado y activo!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 NS Domain : ${C_YELLOW}$NS_DOMAIN${C_NC}"
echo -e " 🔑 Pub Key   : ${C_YELLOW}$PUB_KEY${C_NC}"
echo -e " 🎯 Túnel     : UDP 53 ➔ SSH 22"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_YELLOW}Copia la llave pública (Pub Key) y pégala en HTTP Injector.${C_NC}"
read -p "Presione Enter para regresar..."
