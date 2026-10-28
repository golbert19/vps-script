#!/bin/bash
# ==========================================
# Módulo: HCR Server (Transporte Plain - Nativo)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
HCR_DIR="/etc/vps-manager/hcr"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   INSTALADOR HCR SERVER (OFICIAL AMD64)        ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

read -p "Ingresa el puerto para HCR [Por defecto 8880]: " INPUT_PORT
HCR_PORT=${INPUT_PORT:-8880}
MAX_FRAME="8192"
POLL_TIMEOUT="5s"

mkdir -p /etc/vps-manager
echo "$HCR_PORT" > /etc/vps-manager/hcr_port

echo -e "${C_YELLOW}[+] Preparando entorno y deteniendo servicios...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y wget iptables net-tools ufw >/dev/null 2>&1

systemctl stop hcr-server.service >/dev/null 2>&1
systemctl disable hcr-server.service >/dev/null 2>&1
fuser -k ${HCR_PORT}/tcp >/dev/null 2>&1

rm -rf "$HCR_DIR"
mkdir -p "$HCR_DIR"
cd "$HCR_DIR" || exit 1

echo -e "${C_YELLOW}[+] Descargando binario HCR Server...${C_NC}"
# Intento 1: Repositorio propio
wget -qO hcr-server "https://raw.githubusercontent.com/golbert19/vps-script/main/core/hcr-server"

# Validar si descargó un error 404 (por no estar en el repo) y usar espejo oficial
if [ "$(stat -c%s "hcr-server" 2>/dev/null || echo 0)" -lt 100000 ]; then
    echo -e "${C_YELLOW}[!] Binario no detectado en tu GitHub. Usando espejo oficial...${C_NC}"
    wget -qO hcr-server "https://raw.githubusercontent.com/hexpn/hcr/main/hcr-linux-amd64"
    if [ "$(stat -c%s "hcr-server" 2>/dev/null || echo 0)" -lt 100000 ]; then
        wget -qO hcr-server "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Plugins/hcr"
    fi
fi
chmod +x hcr-server

echo -e "${C_YELLOW}[+] Desplegando servicio Systemd HCR...${C_NC}"
# Construcción directa del servicio prescindiendo de install.sh externo
cat << EOF > /etc/systemd/system/hcr-server.service
[Unit]
Description=HCR relay Server
Wants=network-online.target
After=network-online.target ssh.service sshd.service
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$HCR_DIR
ExecStart=$HCR_DIR/hcr-server --listen :$HCR_PORT --target 127.0.0.1:22 --transport plain --max-download-frame $MAX_FRAME --download-poll-timeout $POLL_TIMEOUT
Restart=on-failure
RestartSec=5s
TimeoutStopSec=15s
KillSignal=SIGTERM
LimitNOFILE=65535
LimitCORE=0
TasksMax=512
MemoryMax=384M
StandardOutput=journal
StandardError=journal
SyslogIdentifier=hcr-server

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hcr-server.service >/dev/null 2>&1
systemctl restart hcr-server.service

echo -e "${C_YELLOW}[+] Configurando Firewall...${C_NC}"
iptables -D INPUT -p tcp --dport $HCR_PORT -j ACCEPT 2>/dev/null
iptables -I INPUT -p tcp --dport $HCR_PORT -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
ufw allow ${HCR_PORT}/tcp >/dev/null 2>&1

IP_VPS=$(curl -s ipv4.icanhazip.com)
DOM=\$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "\$IP_VPS" )

clear
if systemctl is-active --quiet hcr-server.service; then
    echo -e "${C_GREEN}[✔] ¡Motor HCR Oficial instalado y operando con éxito!${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 🌐 Host / IP  : ${C_YELLOW}\$DOM${C_NC}"
    echo -e " 🎯 Puerto TCP : ${C_YELLOW}$HCR_PORT${C_NC}"
    echo -e " 🚀 Transporte : ${C_YELLOW}Plain${C_NC}"
    echo -e " ⚡ Estado     : ${C_GREEN}hcr-server.service Activo${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
else
    echo -e "${C_RED}[✘] Error al iniciar HCR Server. Revisa journalctl -u hcr-server.service${C_NC}"
fi
read -p "Presione Enter para regresar al menú..."
