#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Por favor, ejecuta este script como root (sudo su)."
    exit 1
fi

SERVIDOR_KEYS="http://45.41.207.172:8089"
REPO_URL="https://raw.githubusercontent.com/golbert19/vps-script/main"

export DEBIAN_FRONTEND=noninteractive
DIR="/etc/vps-manager"
mkdir -p "$DIR" "$DIR/core"

MY_IP=$(curl -s --max-time 5 ipv4.icanhazip.com || hostname -I | awk '{print $1}')

clear
echo -e "\033[38;5;208m┌─────────────────────────────────────────────────┐\033[0m"
echo -e "\033[38;5;208m│\033[1;37m        VALIDACIÓN DE LICENCIA - V4.5 LTS        \033[38;5;208m│\033[0m"
echo -e "\033[38;5;208m└─────────────────────────────────────────────────┘\033[0m"
read -p "🔑 Ingrese su Key de único uso: " INPUT_KEY

[[ -z "$INPUT_KEY" ]] && { echo -e "\033[1;31mInstalación cancelada.\033[0m"; exit 1; }

RESPUESTA=$(curl -s --max-time 10 "${SERVIDOR_KEYS}/verify?key=${INPUT_KEY}&ip=${MY_IP}")
if [[ "$RESPUESTA" != "VALID" ]]; then
    echo -e "\033[1;31m[✖] KEY INVÁLIDA O YA UTILIZADA.\033[0m"
    exit 1
fi

echo -e "\033[1;32m[✔] Key autorizada. Descargando módulos core...\033[0m"
sleep 2

# Descargar archivos base y core desde GitHub
wget -O "$DIR/proxy.py" "$REPO_URL/core/proxy.py"
wget -O "$DIR/limiter.sh" "$REPO_URL/core/limiter.sh"
wget -O /usr/local/bin/menu "$REPO_URL/menu.sh"
chmod +x "$DIR/proxy.py" "$DIR/limiter.sh" /usr/local/bin/menu

apt update -y && apt upgrade -y
apt install -y python3 curl wget net-tools stunnel4 openssl jq iptables iptables-persistent unzip psmisc dropbear git socat

# Configurar puertos proxy HTTP (80), BHTTP (8080) y HCR Plain (8180)
for PORT in 80 8080 8180; do
cat <<EOF > /etc/systemd/system/proxy-http-${PORT}.service
[Unit]
Description=Proxy / BHTTP / HCR Engine Puerto ${PORT}
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /etc/vps-manager/proxy.py ${PORT}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable proxy-http-${PORT}.service
    systemctl restart proxy-http-${PORT}.service
done

# Configuración de UDP Custom Oficial con rango masivo (1-65535) en puerto 7300
mkdir -p /root/udp
wget -O /root/udp/udp-custom "https://github.com/http-custom/udp-custom/releases/download/1.0.1/udp-custom-linux-amd64" 2>/dev/null
chmod +x /root/udp/udp-custom

cat <<EOF > /root/udp/config.json
{
  "listen": ":7300",
  "range": "1-65535",
  "stream_buffer": 65535,
  "receive_buffer": 65535,
  "auth": {
    "mode": "passwords"
  }
}
EOF

cat <<EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Server by GolbertVPS (1-65535)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/udp
ExecStart=/root/udp/udp-custom server -c /root/udp/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom
systemctl restart udp-custom

iptables -A INPUT -p udp --dport 1:65535 -j ACCEPT
netfilter-persistent save

rm -f "$0"
clear
echo -e "\033[1;32m[✔] ¡Instalación modular completada con éxito!\033[0m"
menu
