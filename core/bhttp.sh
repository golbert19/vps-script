#!/bin/bash
# ==========================================
# Módulo: BHTTP Original (Compatible con HTTP Custom / UltraCustom)
# Puerto Dinámico Configurable
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
BHTTP_DIR="/etc/vps-manager/bhttp"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   INSTALADOR BHTTP PRO (PUERTO DINÁMICO)       ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

read -p "Ingresa el puerto para BHTTP [Por defecto 8080]: " INPUT_PORT
BHTTP_PORT=${INPUT_PORT:-8080}

# Guardamos el puerto para que el Monitor de Puertos pueda leerlo
mkdir -p /etc/vps-manager
echo "$BHTTP_PORT" > /etc/vps-manager/bhttp_port

echo -e "${C_YELLOW}[+] Preparando entorno y deteniendo servicios anteriores...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y wget iptables net-tools psmisc ufw >/dev/null 2>&1

systemctl stop bhttp.service >/dev/null 2>&1
fuser -k ${BHTTP_PORT}/tcp >/dev/null 2>&1

mkdir -p "$BHTTP_DIR"
cd "$BHTTP_DIR"
rm -f bhttp

echo -e "${C_YELLOW}[+] Descargando binario oficial BHTTP para HTTP Custom...${C_NC}"
# Descarga del binario propietario original usado por HTTP Custom
wget -qO bhttp "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Plugins/bhttp"
if [ ! -s "bhttp" ]; then
    wget -qO bhttp "https://raw.githubusercontent.com/AAAAAEX/Tunnel/main/bhttp"
fi
chmod +x bhttp

# Reglas de Firewall para el puerto elegido
iptables -D INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT 2>/dev/null
iptables -I INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
ufw allow ${BHTTP_PORT}/tcp >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Creando servicio Systemd en el puerto $BHTTP_PORT...${C_NC}"
cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=Official BHTTP Server (Port $BHTTP_PORT)
After=network.target ssh.service

[Service]
Type=simple
User=root
WorkingDirectory=$BHTTP_DIR
ExecStart=$BHTTP_DIR/bhttp -port $BHTTP_PORT
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bhttp.service >/dev/null 2>&1
systemctl restart bhttp.service

IP_VPS=$(curl -s ipv4.icanhazip.com)
DOM=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "$IP_VPS" )

clear
echo -e "${C_GREEN}[✔] ¡Motor BHTTP original instalado y operando!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 Host / IP  : ${C_YELLOW}$DOM${C_NC}"
echo -e " 🎯 Puerto     : ${C_YELLOW}$BHTTP_PORT${C_NC}"
echo -e " ⚡ Estado     : ${C_GREEN}Binario Nativo Activo${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presione Enter para regresar al menú..."
