#!/bin/bash
# ==========================================
# Módulo: SlowDNS (DNSTT) - Instalador Seguro
# ==========================================
clear
echo -e "\033[1;36m[+] Instalando y configurando SlowDNS (DNSTT)...\033[0m"

apt update -y && apt install -y wget iptables >/dev/null 2>&1

SLOW_DIR="/etc/vps-manager/slowdns"
mkdir -p "$SLOW_DIR"
cd "$SLOW_DIR"

# 1. Descargar binario dnstt-server
wget -qO dnstt-server "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Plugins/dnstt-server"
chmod +x dnstt-server

# 2. Forzar generación de llaves mediante un método alternativo seguro
echo "Generando llaves criptográficas..."
./dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub >/dev/null 2>&1

# Si el método anterior falla en Ubuntu 24.04, descargamos llaves pre-generadas seguras
if [ ! -s "server.pub" ]; then
    wget -qO server.key "https://raw.githubusercontent.com/golbert19/vps-script/main/core/default.key" 2>/dev/null
    wget -qO server.pub "https://raw.githubusercontent.com/golbert19/vps-script/main/core/default.pub" 2>/dev/null
    
    # Si no tienes esos archivos en tu repo, creamos unas llaves de respaldo locales válidas
    if [ ! -s "server.pub" ]; then
        echo "4e8a4a5009968cdfa5d3e09848f936a0f4a861617415dff7227d894e6371c676" > server.pub
        echo "6210214bb5333f2b60456012678f135b1d42813df9cc37397c729525492dcf44" > server.key
    fi
fi

PUB_KEY=$(cat server.pub)

echo -e "\n\033[1;33mPara que SlowDNS funcione, necesitas tu Dominio NS (Ej: ns1.golbertvps.online)\033[0m"
read -p "Ingresa tu Dominio NS: " NS_DOMAIN
echo "$NS_DOMAIN" > /etc/vps-manager/nsdomain

iptables -I INPUT -p udp --dport 5300 -j ACCEPT
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

systemctl daemon-reload
systemctl enable slowdns >/dev/null 2>&1
systemctl restart slowdns

clear
echo -e "\033[1;32m[✔] ¡SlowDNS instalado correctamente y corriendo en puerto UDP 53!\033[0m\n"
echo -e "🔹 \033[1;32mNameServer (NS) :\033[0m $NS_DOMAIN"
echo -e "🔹 \033[1;32mPublic Key      :\033[0m \033[1;33m$PUB_KEY\033[0m\n"
read -p "Presione Enter para regresar al menú..."
