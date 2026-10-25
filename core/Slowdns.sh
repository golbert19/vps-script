#!/bin/bash
# ==========================================
# Módulo: SlowDNS (DNSTT) - OpenSSH & SSL
# ==========================================

clear
echo -e "\033[1;36m[+] Instalando y configurando SlowDNS (DNSTT)...\033[0m"

apt update -y && apt install -y wget iptables >/dev/null 2>&1

SLOW_DIR="/etc/vps-manager/slowdns"
mkdir -p "$SLOW_DIR"
cd "$SLOW_DIR"

# Descargar binario desde una fuente estable
if [ ! -f "dnstt-server" ]; then
    wget -qO dnstt-server "https://raw.githubusercontent.com/netobrow/VPS-MX/main/Slow/dnstt-server"
    chmod +x dnstt-server
fi

# Generar llaves
if [ ! -f "server.key" ] || [ ! -f "server.pub" ]; then
    ./dnstt-server -gen key -privkey server.key -pubkey server.pub >/dev/null 2>&1
fi

PUB_KEY=$(cat server.pub 2>/dev/null)

echo -e "\n\033[1;33mPara que SlowDNS funcione, necesitas un subdominio NS (Ej: ns1.golbertvps.online)\033[0m"
read -p "Ingresa tu Dominio NS: " NS_DOMAIN

# Abrir puertos
iptables -I INPUT -p udp --dport 5300 -j ACCEPT
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
iptables-save > /etc/iptables.up.rules

# Crear servicio
cat << EOF > /etc/systemd/system/slowdns.service
[Unit]
Description=SlowDNS Server
After=network.target

[Service]
WorkingDirectory=$SLOW_DIR
ExecStart=$SLOW_DIR/dnstt-server -udp :5300 -privkey-file $SLOW_DIR/server.key $NS_DOMAIN 127.0.0.1:22
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable slowdns >/dev/null 2>&1
systemctl restart slowdns

echo -e "\n\033[1;32m[✔] SlowDNS instalado y corriendo en puerto UDP 53.\033[0m"
echo -e "\033[1;36m================================================\033[0m"
echo -e "🔹 \033[1;32mNameServer (NS):\033[0m $NS_DOMAIN"
echo -e "🔹 \033[1;32mPublic Key:\033[0m $PUB_KEY"
echo -e "\033[1;36m================================================\033[0m"
sleep 5
