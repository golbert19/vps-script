#!/bin/bash
# ==========================================
# Módulo: Instalador SlowDNS (DNSTT) - V5.0 LTS
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
SLOW_DIR="/etc/vps-manager/slowdns"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}       INSTALADOR SLOWDNS (DNSTT SERVER)        ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

# 1. Obtener NS Domain vinculado por el Bot Master
if [ -f /etc/vps-manager/nsdomain ] && [ -s /etc/vps-manager/nsdomain ]; then
    NS_DOMAIN=$(cat /etc/vps-manager/nsdomain)
    echo -e "${C_YELLOW}[+] NS Domain detectado: ${C_GREEN}$NS_DOMAIN${C_NC}"
else
    echo -e "${C_YELLOW}[!] No se detectó un NS Domain configurado por el Bot.${C_NC}"
    read -p "Ingresa tu NS Domain (ej. ns1.tudominio.com): " NS_DOMAIN
    mkdir -p /etc/vps-manager
    echo "$NS_DOMAIN" > /etc/vps-manager/nsdomain
fi

echo -e "${C_YELLOW}[+] Preparando entorno y aplicando enrutamiento IPTables...${C_NC}"
apt-get update -y >/dev/null 2>&1
apt-get install -y iptables iptables-persistent dnsutils wget screen >/dev/null 2>&1

# Detener y limpiar servicios anteriores (si existen)
systemctl stop slowdns.service >/dev/null 2>&1
systemctl stop server-sldns >/dev/null 2>&1
systemctl stop client-sldns >/dev/null 2>&1
systemctl disable server-sldns >/dev/null 2>&1

# 2. Reglas IPTables para redirigir tráfico UDP 53 a 5300 (Bypass de systemd-resolved)
iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null
iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null

iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
iptables -I INPUT -p udp --dport 5300 -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
netfilter-persistent save >/dev/null 2>&1

# 3. Descargar Binarios y Llaves Públicas/Privadas
mkdir -p $SLOW_DIR
cd $SLOW_DIR || exit 1

echo -e "${C_YELLOW}[+] Descargando motor y certificados DNSTT...${C_NC}"
wget -qO server.key "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/server.key"
wget -qO server.pub "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/server.pub"
wget -qO sldns-server "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/sldns-server"

chmod +x sldns-server server.key server.pub

# 4. Crear Servicio Systemd (Apuntando a SSH puerto 22)
echo -e "${C_YELLOW}[+] Configurando servicio nativo SlowDNS...${C_NC}"
cat << EOF > /etc/systemd/system/slowdns.service
[Unit]
Description=SlowDNS Server (DNSTT) - Golbert VPS
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$SLOW_DIR
ExecStart=$SLOW_DIR/sldns-server -udp :5300 -privkey-file $SLOW_DIR/server.key $NS_DOMAIN 127.0.0.1:22
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable slowdns.service >/dev/null 2>&1
systemctl restart slowdns.service

clear
if systemctl is-active --quiet slowdns.service; then
    PUB=$(cat $SLOW_DIR/server.pub)
    echo -e "${C_GREEN}[✔] ¡SlowDNS (DNSTT) instalado y operando con éxito!${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 🌍 NS Domain : ${C_YELLOW}$NS_DOMAIN${C_NC}"
    echo -e " 🗝️ Pub Key   : ${C_YELLOW}$PUB${C_NC}"
    echo -e " 🎯 Redirecc  : ${C_YELLOW}UDP 53 -> 5300 -> SSH(22)${C_NC}"
    echo -e " ⚡ Estado    : ${C_GREEN}slowdns.service Activo${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
else
    echo -e "${C_RED}[✘] Error al iniciar SlowDNS Server.${C_NC}"
    echo -e "Revisa los logs con: journalctl -u slowdns.service --no-pager"
fi
read -p "Presione Enter para regresar al menú..."
