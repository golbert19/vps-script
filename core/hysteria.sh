#!/bin/bash
# ==========================================
# Módulo: Instalador Hysteria V1 (Puertos Personalizables)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
HYS_DIR="/etc/vps-manager/hysteria"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}  INSTALADOR HYSTERIA V1 (ANTI-CONFLICTOS UDP)  ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}1. CREDENCIALES (Deben coincidir con tu App)${C_NC}"
read -p "Ingresa Autenticación Global [Ej: medi:medi]: " HYS_AUTH
HYS_AUTH=${HYS_AUTH:-medi:medi}

read -p "Ingresa Ofuscación Global [Ej: qwertyuiop]: " HYS_OBFS
HYS_OBFS=${HYS_OBFS:-qwertyuiop}

echo -e "\n${C_YELLOW}2. CONFIGURACIÓN DE PUERTOS UDP${C_NC}"
echo -e "Puertos OCUPADOS actualmente: 53, 5300, 25000, 6000-19999 (Zivpn)"
read -p "Puerto Base para Hysteria [Por defecto: 3667]: " BASE_PORT
BASE_PORT=${BASE_PORT:-3667}

read -p "Rango de Port Hopping [Por defecto: 30000:40000]: " HOP_RANGE
HOP_RANGE=${HOP_RANGE:-30000:40000}

mkdir -p $HYS_DIR
cd $HYS_DIR || exit 1
systemctl stop hysteria.service >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Descargando núcleo Hysteria V1 (v1.3.5)...${C_NC}"
wget -qO hysteria "https://github.com/apernet/hysteria/releases/download/app%2Fv1.3.5/hysteria-linux-amd64"
chmod +x hysteria

echo -e "${C_YELLOW}[+] Generando certificados SSL locales...${C_NC}"
openssl req -x509 -nodes -newkey rsa:2048 -keyout server.key -out server.crt -days 3650 -subj "/CN=bing.com" >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Creando config.json avanzado para V1...${C_NC}"
cat << EOF > config.json
{
  "listen": ":$BASE_PORT",
  "cert": "$HYS_DIR/server.crt",
  "key": "$HYS_DIR/server.key",
  "obfs": "$HYS_OBFS",
  "auth_str": "$HYS_AUTH",
  "alpn": "h3",
  "up_mbps": 1000,
  "down_mbps": 1000,
  "disable_mtu_discovery": false
}
EOF

echo -e "${C_YELLOW}[+] Abriendo puertos en Firewall Local (UFW/IPTables)...${C_NC}"
iptables -I INPUT -p udp --dport $BASE_PORT -j ACCEPT 2>/dev/null
iptables -I INPUT -p udp --dport $HOP_RANGE -j ACCEPT 2>/dev/null
ufw allow $BASE_PORT/udp >/dev/null 2>&1
ufw allow $HOP_RANGE/udp >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Aplicando IPTables Port Hopping ($HOP_RANGE -> $BASE_PORT)...${C_NC}"
# Limpiar reglas previas de Hysteria
iptables -t nat -S PREROUTING | grep "REDIRECT" | grep "$BASE_PORT" | sed 's/-A /-D /g' | while read rule; do iptables -t nat $rule; done
# Aplicar nueva regla
iptables -t nat -A PREROUTING -p udp --dport $HOP_RANGE -j REDIRECT --to-ports $BASE_PORT
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
    echo -e "${C_GREEN}[✔] Hysteria V1 instalado correctamente sin conflictos.${C_NC}"
    echo -e " 🚀 Protocolo   : ${C_YELLOW}UDP${C_NC}"
    echo -e " 🎯 Puerto Base : ${C_YELLOW}$BASE_PORT${C_NC}"
    echo -e " 🎯 Port Hopping: ${C_YELLOW}$HOP_RANGE${C_NC}"
    echo -e " 🔑 Auth Pass   : ${C_YELLOW}$HYS_AUTH${C_NC}"
    echo -e " 🛡️ Obfs Pass   : ${C_YELLOW}$HYS_OBFS${C_NC}"
    echo -e "${C_RED}⚠️ MUY IMPORTANTE: Si usas AWS, Oracle, Azure o Google Cloud, debes ir al${C_NC}"
    echo -e "${C_RED}panel web de tu proveedor y abrir los puertos UDP $HOP_RANGE en su Firewall.${C_NC}"
else
    echo -e "${C_RED}[✘] Error al iniciar Hysteria V1.${C_NC}"
    echo -e "Usa 'journalctl -u hysteria -e' para ver el log de errores."
fi
read -p "Presione Enter para regresar..."
