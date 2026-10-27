#!/bin/bash
# ==========================================
# Módulo: Unificador de Puertos y Proxy Inverso
# Golbert VPS - Compatible con Ubuntu 22.04 / 24.04
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   CONFIGURANDO PASARELA NGINX + XRAY + WS       ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

# 1. Detener servicios que compiten por los puertos 80 y 443
systemctl stop stunnel4 >/dev/null 2>&1
systemctl stop xray >/dev/null 2>&1
systemctl stop nginx >/dev/null 2>&1

# 2. Instalar Nginx si no está presente
if ! command -v nginx &> /dev/null; then
    echo -e "${C_YELLOW}[+] Instalando Nginx...${C_NC}"
    apt update -y && apt install -y nginx
fi

# 3. Configurar Nginx para que gestione el puerto 443 y 80 sin conflictos
echo -e "${C_YELLOW}[+] Configurando rutas y proxy inverso...${C_NC}"
cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    # Tráfico HTTP general o redirección a WebSockets internos
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

    # Certificado SSL compartido (puedes usar el que genera tu script)
    ssl_certificate /etc/stunnel/stunnel.pem;
    ssl_certificate_key /etc/stunnel/stunnel.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Enrutar tráfico cifrado hacia Xray o los túneles locales
    location / {
        proxy_pass http://127.0.0.1:10001; # Puerto interno de Xray o tu backend
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

# 4. Verificar sintaxis de Nginx y reiniciar servicios
nginx -t
if [ $? -eq 0 ]; then
    systemctl enable nginx
    systemctl restart nginx
    echo -e "${C_GREEN}[✔] Nginx configurado y operando como pasarela principal en puertos 80 y 443.${C_NC}"
else
    echo -e "${C_RED}[✘] Error en la configuración de Nginx. Revisa la sintaxis.${C_NC}"
fi

# 5. Asegurar que UDP Custom siga activo sin interferir
if systemctl is-active --quiet udp-custom; then
    echo -e "${C_GREEN}[✔] UDP Custom continúa operando sin interrupciones.${C_NC}"
else
    systemctl restart udp-custom
fi

echo -e "${C_GREEN}[✔] ¡Sistema unificado correctamente sin colisión de puertos!${C_NC}"
