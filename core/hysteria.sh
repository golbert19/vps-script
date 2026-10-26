#!/bin/bash
# ==========================================
# Módulo: Hysteria v1 (Legacy QUIC Server)
# Puerto predeterminado: 36712 (UDP) u Operación Libre
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

HYS_DIR="/etc/vps-manager/hysteria"
HYS_PORT=36712

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}     INSTALADOR HYSTERIA v1 (QUIC PROTOCOL)     ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}[+] Actualizando dependencias del sistema...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y wget curl openssl iptables net-tools ufw >/dev/null 2>&1

# Detener servicio anterior si existe
systemctl stop hysteria.service >/dev/null 2>&1

mkdir -p "$HYS_DIR"
cd "$HYS_DIR"

echo -e "${C_YELLOW}[+] Descargando binario oficial de Hysteria v1 (AMD64)...${C_NC}"
wget -qO hysteria "https://github.com/apernet/hysteria/releases/download/v1.3.5/hysteria-linux-amd64"
if [ ! -s "hysteria" ]; then
    wget -qO hysteria "https://github.com/tobyxdd/hysteria/releases/download/v1.3.5/hysteria-linux-amd64"
fi
chmod +x hysteria

echo -e "${C_YELLOW}[+] Generando certificados SSL autofirmados...${C_NC}"
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=US/ST=California/L=Los Angeles/O=Hysteria/CN=hysteria.local" \
    -keyout "$HYS_DIR/server.key" -out "$HYS_DIR/server.crt" 2>/dev/null

echo -e "\n${C_CYAN}================================================${C_NC}"
echo -e " 🔑 ${C_GREEN}CONFIGURACIÓN DE CREDENCIALES (HYSTERIA v1)${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Ingresa una contraseña para Hysteria [Enter para usar 'golbert']: " HYS_PASS
[ -z "$HYS_PASS" ] && HYS_PASS="golbert"

read -p "Ingresa el puerto UDP para Hysteria [Por defecto 36712]: " INPUT_PORT
[ -n "$INPUT_PORT" ] && HYS_PORT="$INPUT_PORT"

# Crear archivo de configuración config.json para Hysteria v1
cat << EOF > "$HYS_DIR/config.json"
{
  "listen": ":$HYS_PORT",
  "protocol": "udp",
  "cert": "$HYS_DIR/server.crt",
  "key": "$HYS_DIR/server.key",
  "up_mbps": 100,
  "down_mbps": 100,
  "obfs": "golbertvps2026",
  "auth": {
    "mode": "passwords",
    "config": [
      "$HYS_PASS"
    ]
  }
}
EOF

# Configurar Firewall y Puertos
iptables -D INPUT -p udp --dport $HYS_PORT -j ACCEPT 2>/dev/null
iptables -I INPUT -p udp --dport $HYS_PORT -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
ufw allow ${HYS_PORT}/udp >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Configurando servicio Systemd para Hysteria v1...${C_NC}"
cat << EOF > /etc/systemd/system/hysteria.service
[Unit]
Description=Hysteria v1 Legacy Server
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

IP_VPS=$(curl -s ipv4.icanhazip.com)
DOM=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "$IP_VPS" )

clear
echo -e "${C_GREEN}[✔] ¡Hysteria v1 instalado y activo con éxito!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 Host / IP  : ${C_YELLOW}$DOM${C_NC}"
echo -e " 🎯 Puerto UDP : ${C_YELLOW}$HYS_PORT${C_NC}"
echo -e " 🔑 Password   : ${C_YELLOW}$HYS_PASS${C_NC}"
echo -e " 🛡️ Obfuscation: ${C_YELLOW}golbertvps2026${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presione Enter para regresar al menú..."
