#!/bin/bash
# ==========================================
# Módulo: SlowDNS (DNSTT) - OpenSSH & SSL (Corregido)
# ==========================================

clear
echo -e "\033[1;36m[+] Instalando y configurando SlowDNS (DNSTT)...\033[0m"

apt update -y && apt install -y wget iptables >/dev/null 2>&1

SLOW_DIR="/etc/vps-manager/slowdns"
mkdir -p "$SLOW_DIR"
cd "$SLOW_DIR"

# 1. Descargar binario desde una fuente 100% estable
if [ ! -f "dnstt-server" ]; then
    echo -e "\033[1;33m[+] Descargando núcleo principal DNSTT...\033[0m"
    wget -qO dnstt-server "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Plugins/dnstt-server"
    chmod +x dnstt-server
fi

# 2. Generar llaves con la SINTAXIS CORRECTA
if [ ! -f "server.key" ] || [ ! -f "server.pub" ]; then
    echo -e "\033[1;33m[+] Generando llaves de seguridad Curve25519...\033[0m"
    ./dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub
fi

# 3. Leer la Key Pública
PUB_KEY=$(cat server.pub 2>/dev/null)

# Si falló, intentar con un binario de respaldo
if [ -z "$PUB_KEY" ]; then
    echo -e "\033[1;31m[!] Error con el primer binario. Descargando versión de respaldo...\033[0m"
    rm -f dnstt-server server.key server.pub
    wget -qO dnstt-server "https://github.com/slpradi/DNSTT-SlowDNS/raw/main/dnstt-server"
    chmod +x dnstt-server
    ./dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub
    PUB_KEY=$(cat server.pub 2>/dev/null)
fi

echo -e "\n\033[1;33mPara que SlowDNS funcione, necesitas un subdominio NS (Ej: ns1.golbertvps.online)\033[0m"
read -p "Ingresa tu Dominio NS: " NS_DOMAIN
echo "$NS_DOMAIN" > /etc/vps-manager/nsdomain

# 4. Abrir puertos en Iptables
iptables -I INPUT -p udp --dport 5300 -j ACCEPT
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
iptables-save > /etc/iptables.up.rules 2>/dev/null

# 5. Crear servicio SystemD
cat << EOF > /etc/systemd/system/slowdns.service
[Unit]
Description=SlowDNS Server Golbert
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
echo -e "\033[1;32m[✔] SlowDNS instalado y corriendo en puerto UDP 53.\033[0m"
echo -e "\033[1;36m================================================\033[0m"
echo -e "🔹 \033[1;32mNameServer (NS):\033[0m $NS_DOMAIN"
echo -e "🔹 \033[1;32mPublic Key:\033[0m $PUB_KEY"
echo -e "\033[1;36m================================================\033[0m"
read -p "Presione Enter para regresar al menú..."
