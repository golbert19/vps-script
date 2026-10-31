#!/bin/bash
# ==========================================
# Módulo: BadVPN Nativo (Puertos 7300 y 7200)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}       INSTALANDO BADVPN (7300 y 7200)          ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}Instalando dependencias de compilación...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y cmake g++ make git screen wget >/dev/null 2>&1

echo -e "${C_YELLOW}Descargando y compilando BadVPN... (Esto puede tardar un minuto)${C_NC}"
cd /tmp
rm -rf badvpn badvpn-build
git clone https://github.com/ambrop72/badvpn.git >/dev/null 2>&1
mkdir -p badvpn-build
cd badvpn-build
cmake ../badvpn -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 >/dev/null 2>&1
make install >/dev/null 2>&1

# Seguro anti-fallos: Si la compilación falla (común en Ubuntu 22.04+), descarga un binario pre-compilado
if [ ! -f "/usr/local/bin/badvpn-udpgw" ]; then
    echo -e "${C_YELLOW}La compilación local falló. Instalando binario pre-compilado...${C_NC}"
    wget -qO /usr/local/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/prem/master/badvpn-udpgw64"
fi

# Otorgar permisos de ejecución obligatorios
chmod +x /usr/local/bin/badvpn-udpgw

echo -e "${C_YELLOW}Configurando servicios Systemd...${C_NC}"

# Crear servicio Systemd para el puerto 7300
cat << EOF > /etc/systemd/system/badvpn-7300.service
[Unit]
Description=BadVPN UDPGW Port 7300
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500 --max-connections-for-client 20
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Crear servicio Systemd para el puerto 7200
cat << EOF > /etc/systemd/system/badvpn-7200.service
[Unit]
Description=BadVPN UDPGW Port 7200
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500 --max-connections-for-client 20
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Recargar entorno y forzar detención de puertos atascados
systemctl daemon-reload
systemctl stop badvpn-7300 badvpn-7200 >/dev/null 2>&1

# Habilitar e iniciar
systemctl enable badvpn-7300 badvpn-7200 >/dev/null 2>&1
systemctl start badvpn-7300 badvpn-7200

# Verificación de estado en vivo
if systemctl is-active --quiet badvpn-7300 && systemctl is-active --quiet badvpn-7200; then
    echo -e "${C_GREEN}[✔] ¡BadVPN configurado y activo en puertos 7300 y 7200!${C_NC}"
else
    echo -e "${C_RED}[!] Advertencia: Los servicios se instalaron pero no reportan estado activo.${C_NC}"
fi

read -p "Presione Enter para regresar..."
