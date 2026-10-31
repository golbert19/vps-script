#!/bin/bash
# ==========================================
# Módulo: BadVPN Nativo (Compilación Completa para Ubuntu/Debian Modernos)
# ==========================================
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'
C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}    COMPILACIÓN E INSTALACIÓN DE BADVPN         ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "\n${C_YELLOW}[1/5] Limpiando instalaciones previas y servicios bloqueados...${C_NC}"
systemctl stop badvpn-7300 badvpn-7200 >/dev/null 2>&1
systemctl disable badvpn-7300 badvpn-7200 >/dev/null 2>&1
rm -f /etc/systemd/system/badvpn-7300.service
rm -f /etc/systemd/system/badvpn-7200.service
rm -f /usr/local/bin/badvpn-udpgw
rm -f /bin/badvpn-udpgw
rm -rf /tmp/badvpn*
systemctl daemon-reload

echo -e "\n${C_YELLOW}[2/5] Instalando dependencias de desarrollo pesadas...${C_NC}"
# Esto garantiza que Ubuntu 22.04+ y Debian 11/12+ tengan las librerías necesarias de C++
apt-get update -y
apt-get install -y build-essential cmake make gcc g++ git wget pkg-config libnss3-dev

echo -e "\n${C_YELLOW}[3/5] Descargando código fuente oficial y compilando...${C_NC}"
echo -e "${C_CYAN}(Este proceso mostrará texto de compilación en pantalla. Es normal.)${C_NC}"
sleep 2

cd /tmp
git clone https://github.com/ambrop72/badvpn.git
cd badvpn
mkdir -p build
cd build

# Proceso de compilación estricto
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
make
make install

echo -e "\n${C_YELLOW}[4/5] Verificando binario y asignando permisos...${C_NC}"
# Buscar el binario en la ruta estándar, si make install falló, lo extraemos manualmente de la carpeta build
if [ -f "/usr/local/bin/badvpn-udpgw" ]; then
    BADVPN_BIN="/usr/local/bin/badvpn-udpgw"
elif [ -f "/tmp/badvpn/build/udpgw/badvpn-udpgw" ]; then
    cp /tmp/badvpn/build/udpgw/badvpn-udpgw /usr/local/bin/badvpn-udpgw
    BADVPN_BIN="/usr/local/bin/badvpn-udpgw"
else
    echo -e "\n${C_RED}[!] Error Crítico: La compilación del código fuente falló.${C_NC}"
    echo -e "${C_RED}Verifica los errores de arriba para saber qué librería le falta a tu sistema.${C_NC}"
    read -p "Presione Enter para salir..."
    exit 1
fi

chmod +x "$BADVPN_BIN"

echo -e "\n${C_YELLOW}[5/5] Creando e iniciando servicios Systemd...${C_NC}"

cat << EOF > /etc/systemd/system/badvpn-7200.service
[Unit]
Description=BadVPN UDPGW Port 7200
After=network.target

[Service]
Type=simple
ExecStart=$BADVPN_BIN --listen-addr 127.0.0.1:7200 --max-clients 1000 --max-connections-for-client 50
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /etc/systemd/system/badvpn-7300.service
[Unit]
Description=BadVPN UDPGW Port 7300
After=network.target

[Service]
Type=simple
ExecStart=$BADVPN_BIN --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 50
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable badvpn-7200 badvpn-7300 >/dev/null 2>&1
systemctl start badvpn-7200 badvpn-7300

sleep 2

# Verificación de estado real
ESTADO_7200=$(systemctl is-active badvpn-7200)
ESTADO_7300=$(systemctl is-active badvpn-7300)

if [ "$ESTADO_7200" = "active" ] && [ "$ESTADO_7300" = "active" ]; then
    echo -e "\n${C_CYAN}================================================${C_NC}"
    echo -e "${C_GREEN} [✔] INSTALACIÓN EXITOSA. BADVPN ESTÁ ACTIVO.${C_NC}"
    echo -e "     - Puerto 7200: ACTIVO"
    echo -e "     - Puerto 7300: ACTIVO"
    echo -e "${C_CYAN}================================================${C_NC}"
else
    echo -e "\n${C_RED}[!] Error: Los servicios se crearon pero no pudieron arrancar.${C_NC}"
    echo -e "${C_YELLOW}Log del puerto 7200:${C_NC}"
    journalctl -u badvpn-7200.service -n 5 --no-pager
fi

read -p "Presione Enter para regresar al menú..."
