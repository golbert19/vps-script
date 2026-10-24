#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Por favor, ejecuta este script como root (sudo su)."
    exit 1
fi

# =========================================================
# CONFIGURACIÓN AUTOMÁTICA CON TU VPS DE KEYS Y GITHUB
# =========================================================
SERVIDOR_KEYS="http://45.41.207.172:8089"
REPO_URL="https://raw.githubusercontent.com/golbert19/vps-script/main"
# =========================================================

export DEBIAN_FRONTEND=noninteractive
DIR="/etc/vps-manager"
mkdir -p "$DIR"

MY_IP=$(curl -s --max-time 5 ipv4.icanhazip.com || hostname -I | awk '{print $1}')

clear
echo -e "\033[38;5;208m┌─────────────────────────────────────────────────┐\033[0m"
echo -e "\033[38;5;208m│\033[1;37m        VALIDACIÓN DE LICENCIA - V4.5 LTS        \033[38;5;208m│\033[0m"
echo -e "\033[38;5;208m└─────────────────────────────────────────────────┘\033[0m"
read -p "🔑 Ingrese su Key de único uso: " INPUT_KEY

if [[ -z "$INPUT_KEY" ]]; then
    echo -e "\033[1;31m[✖] No ingresaste ninguna Key. Instalación cancelada.\033[0m"
    rm -f "$0"
    exit 1
fi

echo -e "\033[1;36m[*] Verificando licencia con el servidor central...\033[0m"
RESPUESTA=$(curl -s --max-time 10 "${SERVIDOR_KEYS}/verify?key=${INPUT_KEY}&ip=${MY_IP}")

if [[ "$RESPUESTA" != "VALID" ]]; then
    echo -e "\033[1;31m[✖] KEY INVÁLIDA O YA UTILIZADA ANTERIORMENTE.\033[0m"
    rm -f "$0"
    exit 1
fi

echo -e "\033[1;32m[✔] Key autorizada con éxito. Iniciando instalación...\033[0m"
sleep 2

clear
echo -e "\033[1;36m=== CONFIGURACIÓN DE DOMINIOS DEL SERVIDOR ===\033[0m"
read -p "Ingresa tu Dominio principal (o ENTER para usar IP $MY_IP): " DOMAIN
read -p "Ingresa tu subdominio NS para SlowDNS (ej. dns.tudominio.com): " NS_DOMAIN

[[ -z "$DOMAIN" ]] && DOMAIN="$MY_IP"
[[ -z "$NS_DOMAIN" ]] && NS_DOMAIN="ns.$DOMAIN"

echo "$DOMAIN" > "$DIR/domain"
echo "$NS_DOMAIN" > "$DIR/ns_domain"

apt update -y && apt upgrade -y
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt install -y python3 curl wget net-tools stunnel4 openssl jq iptables iptables-persistent unzip psmisc dropbear

sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart ssh

# Configuración de Banner SSH inicial
cat << 'EOF' > /etc/issue.net
===================================================
             ⚡ GOLBERT VPS - PREMIUM ⚡             
===================================================
- Uso autorizado solo para clientes registrados.
- Prohibido el Torrent y abusos del servidor.
===================================================
EOF
sed -i 's|#Banner none|Banner /etc/issue.net|g' /etc/ssh/sshd_config
if ! grep -q "Banner /etc/issue.net" /etc/ssh/sshd_config; then
    echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
fi
systemctl restart ssh

# Configuración de Dropbear (Puertos 143 y 109)
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 109"/g' /etc/default/dropbear
echo 'DROPBEAR_BANNER="/etc/issue.net"' >> /etc/default/dropbear
systemctl enable dropbear
systemctl restart dropbear

wget -O "$DIR/proxy.py" "$REPO_URL/proxy.py"
wget -O "$DIR/limiter.sh" "$REPO_URL/limiter.sh"
wget -O /usr/local/bin/menu "$REPO_URL/menu.sh"
chmod +x "$DIR/proxy.py" "$DIR/limiter.sh" /usr/local/bin/menu

# 1. Servicios Proxy HTTP, WS, BHTTP (80) y HCR (8180)
for PORT in 80 8080 8180; do
cat <<EOF > /etc/systemd/system/proxy-http-${PORT}.service
[Unit]
Description=Proxy / BHTTP / HCR / WS Puerto ${PORT}
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

# 2. Servicio Limitador Automático Multi-Login
cat <<EOF > /etc/systemd/system/vps-limiter.service
[Unit]
Description=Limitador Multi-Login y Expiracion SSH
After=network.target

[Service]
Type=simple
User=root
ExecStart=/bin/bash /etc/vps-manager/limiter.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable vps-limiter
systemctl restart vps-limiter

# 3. Servicio TLS/SSL / TLS WS (Stunnel4 en Puerto 443)
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj "/C=PE/ST=Lima/L=Lima/O=GolbertVPS/CN=$DOMAIN" \
    -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem

cat <<EOF > /etc/stunnel/stunnel.conf
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ssh-tls]
accept = 443
connect = 127.0.0.1:22
EOF
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4 2>/dev/null
systemctl enable stunnel4
systemctl restart stunnel4

# 4. Servicio DNSTT (SlowDNS en Puertos 22, 53, 443)
wget -O /usr/local/bin/dnstt-server "https://raw.githubusercontent.com/bugfloyd/dnstt-deploy/main/bin/dnstt-server-linux-amd64"
chmod +x /usr/local/bin/dnstt-server
/usr/local/bin/dnstt-server -gen-key -privkey-file "$DIR/server.key" -pubkey-file "$DIR/server.pub"

systemctl stop systemd-resolved 2>/dev/null
systemctl disable systemd-resolved 2>/dev/null
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

iptables -I INPUT -p udp --dport 5300 -j ACCEPT
iptables -I INPUT -p udp --dport 53 -j ACCEPT
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
netfilter-persistent save

cat <<EOF > /etc/systemd/system/dnstt.service
[Unit]
Description=DNSTT SlowDNS Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/dnstt-server -udp :5300 -privkey-file /etc/vps-manager/server.key ${NS_DOMAIN} 127.0.0.1:22
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable dnstt
systemctl restart dnstt

# 5. Servicio V2Ray / Xray (VMess NoTLS en 80 y TLS en 443)
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
mkdir -p /usr/local/etc/xray
cat <<EOF > /usr/local/etc/xray/config.json
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 80,
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/vmess" }
      }
    },
    {
      "port": 443,
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{
            "certificateFile": "/etc/stunnel/stunnel.pem",
            "keyFile": "/etc/stunnel/stunnel.pem"
          }]
        },
        "wsSettings": { "path": "/vmess-tls" }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF
systemctl enable xray
systemctl restart xray

# 6. ZIVPN (Puertos 20000-29999 UDP)
mkdir -p /etc/zivpn
wget -O /usr/local/bin/zivpn "https://github.com/zahidbd2/zivpn/releases/download/v1.0.8/zivpn-linux-amd64" 2>/dev/null || true
chmod +x /usr/local/bin/zivpn 2>/dev/null || true

cat <<EOF > /etc/zivpn/config.json
{
  "listen": ":20000",
  "udp_ports": "20000-29999",
  "password": "golbertvps"
}
EOF

cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=ZIVPN UDP Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/zivpn -c /etc/zivpn/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable zivpn 2>/dev/null || true
systemctl restart zivpn 2>/dev/null || true

# 7. Servicio Hysteria2 (Puerto dinámico / Random)
mkdir -p /etc/hysteria
wget -O /usr/local/bin/hysteria "https://github.com/apernet/hysteria/releases/download/v2.2.1/hysteria-linux-amd64"
chmod +x /usr/local/bin/hysteria

cat <<EOF > /etc/hysteria/config.yaml
listen: :36712
tls:
  cert: /etc/stunnel/stunnel.pem
  key: /etc/stunnel/stunnel.pem
auth:
  type: password
  password: golbert123
masquerade:
  type: proxy
  proxy:
    url: https://bing.com
    rewriteHost: true
EOF

cat <<EOF > /etc/systemd/system/hysteria.service
[Unit]
Description=Hysteria2 Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable hysteria
systemctl restart hysteria

# 8. Servicio BadVPN UDPGW (Puerto 7300 para UDP Custom 1-65535)
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw64"
chmod +x /usr/bin/badvpn-udpgw
cat <<EOF > /etc/systemd/system/udpgw.service
[Unit]
Description=BadVPN UDPGW 7300
After=network.target

[Service]
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 100
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable udpgw
systemctl restart udpgw

# Limpiar instalador temporal
rm -f "$0"

clear
echo -e "\033[38;5;208m┌─────────────────────────────────────────────────┐\033[0m"
echo -e "\033[38;5;208m│\033[1;32m     INSTALACIÓN V4.5 LTS COMPLETADA CON ÉXITO   \033[38;5;208m│\033[0m"
echo -e "\033[38;5;208m└─────────────────────────────────────────────────┘\033[0m"
sleep 2

# Lanzar el menú principal de forma automática inmediatamente termina
menu
