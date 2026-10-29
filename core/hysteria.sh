#!/bin/bash
# ==========================================
# Módulo: Instalador Hysteria V1 (Configuración Estable)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
HYS_DIR="/etc/vps-manager/hysteria"
BASE_PORT="3667"
HOP_RANGE="36000:65000"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}    INSTALADOR HYSTERIA V1 (TÚNEL GLOBAL UDP)   ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

read -p "Ingresa Autenticación Global [Ej: medi:medi]: " HYS_AUTH
HYS_AUTH=${HYS_AUTH:-medi:medi}

read -p "Ingresa Ofuscación Global [Ej: qwertyuiop]: " HYS_OBFS
HYS_OBFS=${HYS_OBFS:-qwertyuiop}

mkdir -p $HYS_DIR
cd $HYS_DIR || exit 1
systemctl stop hysteria.service >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Descargando núcleo Hysteria V1 (v1.3.5)...${C_NC}"
wget -qO hysteria "https://github.com/apernet/hysteria/releases/download/app%2Fv1.3.5/hysteria-linux-amd64"
chmod +x hysteria

echo -e "${C_YELLOW}[+] Generando certificados SSL locales...${C_NC}"
openssl req -x509 -nodes -newkey rsa:2048 -keyout server.key -out server.crt -days 3650 -subj "/CN=bing.com" >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Creando config.json estable para V1...${C_NC}"
cat << EOF > config.json
{
  "listen": ":$BASE_PORT",
  "cert": "$HYS_DIR/server.crt",
  "key": "$HYS_DIR/server.key",
  "obfs": "$HYS_OBFS",
  "auth_str": "$HYS_AUTH",
  "up_mbps": 1000,
  "down_mbps": 1000
}
EOF

echo -e "${C_YELLOW}[+] Abriendo puertos en Firewall Local...${C_NC}"
iptables -I INPUT -p udp --dport $BASE_PORT -j ACCEPT 2>/dev/null
iptables -I INPUT -p udp --dport 36000:65000 -j ACCEPT 2>/dev/null
ufw allow $BASE_PORT/udp >/dev/null 2>&1
ufw allow 36000:65000/udp >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Aplicando IPTables Port Hopping ($HOP_RANGE)...${C_NC}"
# Limpiar reglas viejas para evitar duplicados
iptables -t nat -D PREROUTING -p udp --dport 10000:65000 -j REDIRECT --to-ports $BASE_PORT 2>/dev/null
iptables -t nat -D PREROUTING -p udp --dport 36000:65000 -j REDIRECT --to-ports $BASE_PORT 2>/dev/null
# Aplicar regla limpia
iptables -t nat -A PREROUTING -p udp --dport 36000:65000 -j REDIRECT --to-ports $BASE_PORT
iptables-save > /etc/iptables.up.rules 2>/dev/null
netfilter-persistent save >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Creando servicio Systemd...${C_NC}"
cat << EOF > /etc/systemd/system/hysteria.service
[Unit]
Description=Hysteria V1 Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$HYS_DIR
ExecStart=$HYS_DIR/hysteria -c $HYS_DIR/config.json server
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
    echo -e "${C_GREEN}[✔] Hysteria V1 instalado correctamente.${C_NC}"
    echo -e " 🚀 Protocolo   : ${C_YELLOW}UDP${C_NC}"
    echo -e " 🎯 Port Hopping: ${C_YELLOW}36000-65000${C_NC}"
    echo -e " 🔑 Auth Pass   : ${C_YELLOW}$HYS_AUTH${C_NC}"
    echo -e " 🛡️ Obfs Pass   : ${C_YELLOW}$HYS_OBFS${C_NC}"
else
    echo -e "${C_RED}[✘] Error al iniciar Hysteria V1.${C_NC}"
fi
read -p "Presione Enter para regresar..."
