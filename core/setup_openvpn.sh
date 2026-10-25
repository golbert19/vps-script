#!/bin/bash
# ==========================================
# Módulo: OpenVPN + Servidor Web de Perfiles (2081)
# ==========================================

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear
echo -e "${CYAN}[+] Instalando OpenVPN y dependencias...${NC}"
apt update -y && apt install -y openvpn iptables wget python3 curl >/dev/null 2>&1

# Crear directorio para los perfiles
OVPN_DIR="/etc/vps-manager/openvpn_files"
mkdir -p "$OVPN_DIR"

# Crear script de Python para servir la web en el puerto 2081
cat << 'EOF' > /etc/vps-manager/server_web.py
import http.server
import socketserver
import os

PORT = 2081
DIRECTORY = "/etc/vps-manager/openvpn_files"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
    print(f"Servidor web OpenVPN corriendo en puerto {PORT}")
    httpd.serve_forever()
EOF

chmod +x /etc/vps-manager/server_web.py

# Crear servicio Systemd para mantener el puerto 2081 encendido siempre
cat << 'EOF' > /etc/systemd/system/openvpn-web.service
[Unit]
Description=Servidor Web de Perfiles OpenVPN Golbert
After=network.target

[Service]
ExecStart=/usr/bin/python3 /etc/vps-manager/server_web.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openvpn-web >/dev/null 2>&1
systemctl restart openvpn-web

IP_VPS=$(curl -s --max-time 3 ipv4.icanhazip.com || hostname -I | awk '{print $1}')
echo -e "\n${GREEN}[✔] ¡OpenVPN y Servidor Web configurados con éxito!${NC}"
echo -e "Enlace activo en: ${YELLOW}http://$IP_VPS:2081${NC}"
sleep 3
