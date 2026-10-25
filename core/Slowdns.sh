#!/bin/bash
# ==========================================
# Módulo: SlowDNS (DNSTT) - Anti-Timeout
# ==========================================
clear
echo -e "\033[1;36m[+] Instalando y configurando SlowDNS (Anti-Timeout)...\033[0m"

# 1. Liberar el puerto 53 (Apagar systemd-resolved)
systemctl stop systemd-resolved >/dev/null 2>&1
systemctl disable systemd-resolved >/dev/null 2>&1
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

apt update -y && apt install -y wget iptables >/dev/null 2>&1

SLOW_DIR="/etc/vps-manager/slowdns"
mkdir -p "$SLOW_DIR"
cd "$SLOW_DIR"

# 2. Descargar binario
wget -qO dnstt-server "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Plugins/dnstt-server"
chmod +x dnstt-server

# 3. Generar llaves o usar respaldo
./dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub >/dev/null 2>&1
if [ ! -s "server.pub" ]; then
    echo "4e8a4a5009968cdfa5d3e09848f936a0f4a861617415dff7227d894e6371c676" > server.pub
    echo "6210214bb5333f2b60456012678f135b1d42813df9cc37397c729525492dcf44" > server.key
fi
PUB_KEY=$(cat server.pub)

echo -e "\n\033[1;33mPara que SlowDNS funcione, necesitas tu Dominio NS (Ej: ns1.golbertvps.online)\033[0m"
read -p "Ingresa tu Dominio NS: " NS_DOMAIN
echo "$NS_DOMAIN" > /etc/vps-manager/nsdomain

# 4. Forzar redirección limpia del puerto 53
iptables -I INPUT -p udp --dport 5300 -j ACCEPT
iptables -I INPUT -p udp --dport 53 -j ACCEPT
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
iptables-save > /etc/iptables.up.rules 2>/dev/null

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

systemctl daemon-reload; systemctl enable slowdns >/dev/null 2>&1; systemctl restart slowdns

clear
echo -e "\033[1;32m[✔] ¡SlowDNS instalado sin bloqueos en el puerto 53!\033[0m\n"
echo -e "🔹 \033[1;32mNameServer (NS) :\033[0m $NS_DOMAIN"
echo -e "🔹 \033[1;32mPublic Key      :\033[0m \033[1;33m$PUB_KEY\033[0m\n"
echo -e "\033[1;31m⚠️ ATENCIÓN CLOUDFLARE:\033[0m"
echo -e "Asegúrate de tener un registro 'A' (ej: dns.tudominio.com) apuntando a la IP de la VPS."
echo -e "Y un registro 'NS' (ej: ns1.tudominio.com) apuntando a dns.tudominio.com."
read -p "Presione Enter para regresar..."
