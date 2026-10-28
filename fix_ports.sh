#!/bin/bash
# ==========================================
# Módulo: Unificador de Puertos y Proxy Inverso (Corregido)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   CONFIGURANDO PASARELA NGINX + XRAY + WS       ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}[+] Reconfigurando puertos internos...${C_NC}"
# 1. Mover Python WS del puerto 80 al 8080 para evitar colisión con Nginx
if [ -f /etc/vps-manager/core/proxy.py ]; then
    sed -i "s/server.bind(('0.0.0.0', 80))/server.bind(('0.0.0.0', 8080))/g" /etc/vps-manager/core/proxy.py
    systemctl restart ws-python >/dev/null 2>&1
fi

# 2. Generar certificado SSL si no existe (vital para que Nginx arranque)
mkdir -p /etc/stunnel
if [ ! -f /etc/stunnel/stunnel.pem ]; then
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "/C=PE/ST=Lima/L=Lima/O=Golbert/CN=golbertvps.online" -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem >/dev/null 2>&1
fi

# 3. Configurar Stunnel4 para operar en el puerto 444
cat << 'EOF' > /etc/stunnel/stunnel.conf
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ssl-proxy]
accept = 444
connect = 127.0.0.1:8080
EOF
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4

echo -e "${C_YELLOW}[+] Liberando puertos 80 y 443 de forma forzada...${C_NC}"
systemctl stop stunnel4 >/dev/null 2>&1
systemctl stop xray >/dev/null 2>&1
systemctl stop nginx >/dev/null 2>&1
fuser -k 80/tcp >/dev/null 2>&1
fuser -k 443/tcp >/dev/null 2>&1

if ! command -v nginx &> /dev/null; then
    echo -e "${C_YELLOW}[+] Instalando Nginx...${C_NC}"
    apt update -y && apt install -y nginx >/dev/null 2>&1
fi

echo -e "${C_YELLOW}[+] Aplicando reglas de enrutamiento Nginx...${C_NC}"
cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    server_name _;
    ssl_certificate /etc/stunnel/stunnel.pem;
    ssl_certificate_key /etc/stunnel/stunnel.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    location / {
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
EOF

# 4. Reiniciar y verificar servicios
nginx -t
if [ $? -eq 0 ]; then
    systemctl enable nginx >/dev/null 2>&1
    systemctl restart nginx
    systemctl restart xray >/dev/null 2>&1
    systemctl restart stunnel4 >/dev/null 2>&1
    echo -e "${C_GREEN}[✔] Nginx configurado y operando como pasarela principal.${C_NC}"
else
    echo -e "${C_RED}[✘] Error en la sintaxis de Nginx.${C_NC}"
fi

if systemctl is-active --quiet udp-custom; then
    echo -e "${C_GREEN}[✔] UDP Custom continúa operando sin interrupciones.${C_NC}"
else
    systemctl restart udp-custom >/dev/null 2>&1
fi

echo -e "${C_GREEN}[✔] ¡Sistema unificado correctamente sin colisión de puertos!${C_NC}"
