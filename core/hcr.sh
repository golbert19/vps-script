#!/bin/bash
# ==========================================
# Módulo: HCR Proxy Server (Nativo Systemd con Espejos)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
HCR_DIR="/etc/vps-manager/hcr"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   INSTALADOR HCR SERVER (DIRECTO AMD64)        ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

read -p "Ingresa el puerto para HCR [Por defecto 8880]: " INPUT_PORT
HCR_PORT=${INPUT_PORT:-8880}

mkdir -p /etc/vps-manager
echo "$HCR_PORT" > /etc/vps-manager/hcr_port

echo -e "${C_YELLOW}[+] Preparando entorno y deteniendo servicios antiguos...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y wget iptables net-tools psmisc ufw >/dev/null 2>&1

systemctl stop hcr.service >/dev/null 2>&1
systemctl disable hcr.service >/dev/null 2>&1
rm -f /etc/systemd/system/hcr.service
systemctl stop hcr-server.service >/dev/null 2>&1
fuser -k ${HCR_PORT}/tcp >/dev/null 2>&1

mkdir -p $HCR_DIR
cd $HCR_DIR || exit 1

echo -e "${C_YELLOW}[+] Descargando binario HCR Server...${C_NC}"
# 1. Intentar desde tu propio repositorio
wget -qO hcr-server "https://raw.githubusercontent.com/golbert19/vps-script/main/core/hcr-server"

# 2. Si falla (archivo de 0 bytes o 404), usar espejos alternativos
if [ "$(stat -c%s "hcr-server" 2>/dev/null || echo 0)" -lt 1000 ]; then
    echo -e "${C_YELLOW}[!] Buscando en espejos externos activos...${C_NC}"
    URLS=(
        "https://raw.githubusercontent.com/ChumoGH/ChumoGH-Script/master/BINARIOS/hcr"
        "https://raw.githubusercontent.com/powermx/hcr/main/hcr"
        "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Plugins/hcr"
    )
    for url in "${URLS[@]}"; do
        wget -qO hcr-server "$url"
        # Si el archivo pesa más de 500KB, es el binario correcto
        if [ "$(stat -c%s "hcr-server" 2>/dev/null || echo 0)" -gt 500000 ]; then
            break
        fi
    done
fi

chmod +x hcr-server

# Verificación final de integridad
if [ "$(stat -c%s "hcr-server" 2>/dev/null || echo 0)" -lt 500000 ]; then
    echo -e "${C_RED}[✘] Error Crítico: No se pudo descargar el binario desde ningún servidor.${C_NC}"
    read -p "Presione Enter para regresar..."
    exit 1
fi

echo -e "${C_YELLOW}[+] Creando servicio Systemd nativo...${C_NC}"
cat << EOF > /etc/systemd/system/hcr-server.service
[Unit]
Description=HCR Proxy Server Nativo
After=network-online.target ssh.service

[Service]
Type=simple
User=root
WorkingDirectory=$HCR_DIR
ExecStart=$HCR_DIR/hcr-server --listen :$HCR_PORT --target 127.0.0.1:22 --transport plain --max-download-frame 8192 --download-poll-timeout 5s
Restart=always
RestartSec=3
LimitNOFILE=65535

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
DOM=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "$IP_VPS" )

clear
if systemctl is-active --quiet hcr-server.service; then
    echo -e "${C_GREEN}[✔] ¡Motor HCR Oficial instalado y operando con éxito!${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 🌐 Host / IP  : ${C_YELLOW}$DOM${C_NC}"
    echo -e " 🎯 Puerto TCP : ${C_YELLOW}$HCR_PORT${C_NC}"
    echo -e " 🚀 Transporte : ${C_YELLOW}Plain${C_NC}"
    echo -e " ⚡ Estado     : ${C_GREEN}hcr-server.service Activo${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
else
    echo -e "${C_RED}[✘] Error al iniciar HCR Server.${C_NC}"
    echo -e "Detalle del error:"
    journalctl -u hcr-server.service -n 10 --no-pager
fi
read -p "Presione Enter para regresar al menú..."
