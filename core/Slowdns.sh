#!/bin/bash
# ==========================================
# Módulo: SlowDNS (DNSTT Oficial de BamSoftware)
# Puertos: 53 y 5300 (UDP) - Vía Go Compilation
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
SLOW_DIR="/etc/vps-manager/slowdns"
mkdir -p $SLOW_DIR

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   INSTALADOR SLOWDNS (DNSTT - OFICIAL GO)      ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

read -p "Ingresa tu dominio NameServer (Ej: ns.dominio.com): " NS_DOM
if [ -z "$NS_DOM" ]; then
    echo -e "${C_RED}[!] Error: El dominio NS es obligatorio.${C_NC}"; sleep 2; exit 1
fi
echo "$NS_DOM" > /etc/vps-manager/nsdomain

echo -e "${C_YELLOW}[+] Instalando Git, Golang y dependencias de red...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y git golang iptables iptables-persistent ufw >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Liberando el puerto 53 (Deteniendo systemd-resolved)...${C_NC}"
systemctl stop systemd-resolved >/dev/null 2>&1
systemctl disable systemd-resolved >/dev/null 2>&1
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
fuser -k 53/tcp >/dev/null 2>&1
fuser -k 53/udp >/dev/null 2>&1
systemctl stop slowdns >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Clonando repositorio oficial (BamSoftware)...${C_NC}"
cd $SLOW_DIR
rm -rf dnstt
git clone https://www.bamsoftware.com/git/dnstt.git >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Compilando binario dnstt-server...${C_NC}"
cd dnstt/dnstt-server
go build

if [ ! -f "$SLOW_DIR/server.key" ]; then
    echo -e "${C_YELLOW}[+] Generando llaves criptográficas...${C_NC}"
    ./dnstt-server -gen-key -privkey-file $SLOW_DIR/server.key -pubkey-file $SLOW_DIR/server.pub
fi

echo -e "${C_YELLOW}[+] Configurando Firewall (Puertos 53 y 5300)...${C_NC}"
iptables -D INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null
iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null
iptables -I INPUT -p udp --dport 53 -j ACCEPT
iptables -I INPUT -p udp --dport 5300 -j ACCEPT

# Magia NAT: Todo lo que entre por el 5300 va directo al 53
iptables -t nat -D PREROUTING -p udp --dport 5300 -j REDIRECT --to-ports 53 2>/dev/null
iptables -t nat -I PREROUTING -p udp --dport 5300 -j REDIRECT --to-ports 53
iptables-save > /etc/iptables.up.rules 2>/dev/null

ufw allow 53/udp >/dev/null 2>&1
ufw allow 5300/udp >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Creando servicio Anti-Caídas Systemd...${C_NC}"
cat << EOF > /etc/systemd/system/slowdns.service
[Unit]
Description=DNSTT SlowDNS Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$SLOW_DIR/dnstt/dnstt-server
# Se conecta al puerto SSH local 22 para dar internet
ExecStart=$SLOW_DIR/dnstt/dnstt-server/dnstt-server -udp :53 -privkey-file $SLOW_DIR/server.key $NS_DOM 127.0.0.1:22
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable slowdns >/dev/null 2>&1
systemctl restart slowdns

PUB_KEY=$(cat $SLOW_DIR/server.pub)

clear
echo -e "${C_GREEN}[✔] ¡SlowDNS compilado e instalado con éxito!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 Dominio NS : ${C_YELLOW}$NS_DOM${C_NC}"
echo -e " 🎯 Puertos    : ${C_YELLOW}53 y 5300 (UDP)${C_NC}"
echo -e " 🔑 Pub Key    : ${C_GREEN}$PUB_KEY${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presione Enter para regresar al menú..."
