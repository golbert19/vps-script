#!/bin/bash
# ==========================================
# Módulo: HCR Proxy Server (Nativo Linux amd64)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
HCR_DIR="/etc/vps-manager/hcr"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   INSTALADOR HCR SERVER (OFICIAL AMD64)        ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

read -p "Ingresa el puerto para HCR [Por defecto 8880]: " INPUT_PORT
HCR_PORT=${INPUT_PORT:-8880}

# Guardamos el puerto elegido para que el monitor de puertos lo lea
mkdir -p /etc/vps-manager
echo "$HCR_PORT" > /etc/vps-manager/hcr_port

echo -e "${C_YELLOW}[+] Preparando entorno y deteniendo servicios antiguos...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y wget iptables net-tools psmisc ufw >/dev/null 2>&1

# Limpiamos el servicio viejo si existe y detenemos cualquier proceso en el puerto
systemctl stop hcr.service >/dev/null 2>&1
systemctl disable hcr.service >/dev/null 2>&1
rm -f /etc/systemd/system/hcr.service
systemctl stop hcr-server.service >/dev/null 2>&1
fuser -k ${HCR_PORT}/tcp >/dev/null 2>&1

mkdir -p $HCR_DIR
cd $HCR_DIR || exit 1

echo -e "${C_YELLOW}[+] Descargando binario y script oficial desde GitHub...${C_NC}"
# Descargamos los archivos alojados en tu repositorio
wget -qO hcr-server "https://raw.githubusercontent.com/golbert19/vps-script/main/core/hcr-server"
wget -qO install.sh "https://raw.githubusercontent.com/golbert19/vps-script/main/core/install.sh"
chmod +x hcr-server install.sh

# Ajustamos los parámetros de rendimiento (Opcional, para mejor estabilidad)
sed -i 's/MAX_DOWNLOAD_FRAME="6144"/MAX_DOWNLOAD_FRAME="8192"/g' install.sh
sed -i 's/DOWNLOAD_POLL_TIMEOUT="8s"/DOWNLOAD_POLL_TIMEOUT="5s"/g' install.sh

echo -e "${C_YELLOW}[+] Desplegando servicio HCR (Transporte Plain)...${C_NC}"
# Ejecutamos el instalador oficial que creará hcr-server.service
./install.sh --port $HCR_PORT --transport plain

echo -e "${C_YELLOW}[+] Configurando Firewall...${C_NC}"
iptables -D INPUT -p tcp --dport $HCR_PORT -j ACCEPT 2>/dev/null
iptables -I INPUT -p tcp --dport $HCR_PORT -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
ufw allow ${HCR_PORT}/tcp >/dev/null 2>&1

IP_VPS=$(curl -s ipv4.icanhazip.com)
DOM=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "$IP_VPS" )

clear
# Verificamos el nuevo nombre del servicio oficial
if systemctl is-active --quiet hcr-server.service; then
    echo -e "${C_GREEN}[✔] ¡Motor HCR Oficial instalado y operando con éxito!${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 🌐 Host / IP  : ${C_YELLOW}$DOM${C_NC}"
    echo -e " 🎯 Puerto TCP : ${C_YELLOW}$HCR_PORT${C_NC}"
    echo -e " 🚀 Transporte : ${C_YELLOW}Plain${C_NC}"
    echo -e " ⚡ Estado     : ${C_GREEN}hcr-server.service Activo${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
else
    echo -e "${C_RED}[✘] Error al iniciar HCR Server. Revisa journalctl -u hcr-server.service${C_NC}"
fi
read -p "Presione Enter para regresar al menú..."
