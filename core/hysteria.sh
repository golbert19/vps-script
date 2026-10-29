#!/bin/bash
# ==========================================
# Módulo: Instalador Hysteria V2 (UDP Port Hopping)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
HYS_DIR="/etc/vps-manager/hysteria"
BASE_PORT="3667"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}         INSTALADOR HYSTERIA V2 (UDP)           ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

mkdir -p $HYS_DIR
cd $HYS_DIR || exit 1

echo -e "${C_YELLOW}[+] Descargando núcleo Hysteria V2...${C_NC}"
wget -qO hysteria "https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64"
chmod +x hysteria

echo -e "${C_YELLOW}[+] Generando certificados SSL locales (Insecure ON)...${C_NC}"
openssl req -x509 -nodes -newkey rsa:2048 -keyout server.key -out server.crt -days 3650 -subj "/CN=bing.com" >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Creando archivo de configuración V2...${C_NC}"
cat << EOF > config.yaml
listen: :$BASE_PORT
tls:
  cert: $HYS_DIR/server.crt
  key: $HYS_DIR/server.key
auth:
  type: password
  password: 1234567890zxcvbnmasd
obfs:
  type: salamander
  salamander:
    password: qwertyuiop
EOF

echo -e "${C_YELLOW}[+] Aplicando IPTables para Port Hopping (10000-65000)...${C_NC}"
iptables -t nat -D PREROUTING -p udp --dport 10000:65000 -j REDIRECT --to-ports $BASE_PORT 2>/dev/null
iptables -t nat -A PREROUTING -p udp --dport 10000:65000 -j REDIRECT --to-ports $BASE_PORT
iptables-save > /etc/iptables.up.rules 2>/dev/null
netfilter-persistent save >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Creando servicio Systemd...${C_NC}"
cat << EOF > /etc/systemd/system/hysteria.service
[Unit]
Description=Hysteria V2 Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$HYS_DIR
ExecStart=$HYS_DIR/hysteria server -c $HYS_DIR/config.yaml
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hysteria.service >/dev/null 2>&1
systemctl restart hysteria.service

clear
if systemctl is-active --quiet hysteria.service; then
    echo -e "${C_GREEN}[✔] Hysteria V2 instalado correctamente.${C_NC}"
    echo -e " 🚀 Protocolo   : ${C_YELLOW}UDP${C_NC}"
    echo -e " 🎯 Port Hopping: ${C_YELLOW}10000-65000${C_NC}"
    echo -e " 🔑 Auth Pass   : ${C_YELLOW}1234567890zxcvbnmasd${C_NC}"
    echo -e " 🛡️ Obfs Pass   : ${C_YELLOW}qwertyuiop${C_NC}"
else
    echo -e "${C_RED}[✘] Error al iniciar Hysteria V2.${C_NC}"
fi
read -p "Presione Enter para regresar..."
