#!/bin/bash
# ==========================================
# Módulo: UDP Custom (Oficial eProxy Devs)
# Soporta rango completo 1-65535 + Ubuntu 22.04/24.04
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
UDP_DIR="/etc/vps-manager/udp"
UDP_PORT=36712

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   INSTALADOR UDP CUSTOM (RANGO 1-65535)        ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

# 1. Detener servicios previos y preparar directorio
systemctl stop udp-custom >/dev/null 2>&1
fuser -k ${UDP_PORT}/udp >/dev/null 2>&1
mkdir -p "$UDP_DIR"
cd "$UDP_DIR" || exit 1
rm -f udp-custom config.json

# 2. Descargar binario oficial verificando tamaño real
echo -e "${C_YELLOW}[+] Descargando binario oficial UDP Custom...${C_NC}"
wget -qO udp-custom "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Plugins/udp-custom"
if [ "$(stat -c%s "udp-custom" 2>/dev/null || echo 0)" -lt 100000 ]; then
    wget -qO udp-custom "https://github.com/UDPcustom/udp-custom/releases/download/1.0.3/udp-custom-linux-amd64"
fi
chmod +x "$UDP_DIR/udp-custom"

# 3. Crear config.json obligatorio para el binario
echo -e "${C_YELLOW}[+] Generando archivo config.json...${C_NC}"
cat << EOF > "$UDP_DIR/config.json"
{
  "listen": ":${UDP_PORT}",
  "stream_buffer": 33554432,
  "receive_buffer": 83886080,
  "auth": {
    "mode": "passwords"
  }
}
EOF
chmod 644 "$UDP_DIR/config.json"

# 4. Ajustar encriptación PAM a SHA512 (compatibilidad Ubuntu 22.04/24.04)
echo -e "${C_YELLOW}[+] Ajustando compatibilidad de contraseñas PAM...${C_NC}"
if [ -f /etc/pam.d/common-password ]; then
    sed -i 's/yescrypt/sha512/g' /etc/pam.d/common-password
fi
if [ -f /etc/login.defs ]; then
    sed -i 's/^ENCRYPT_METHOD.*/ENCRYPT_METHOD SHA512/g' /etc/login.defs
fi

# 5. Habilitar IP Forward y redirección NAT para el rango 1-65535
echo -e "${C_YELLOW}[+] Configurando redirección de puertos 1-65535 en Firewall...${C_NC}"
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

NET_IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

# Limpiar reglas previas del puerto y aplicar redirección de rango
iptables -t nat -D PREROUTING -i "$NET_IFACE" -p udp --dport 1:65535 -j DNAT --to-destination :${UDP_PORT} 2>/dev/null
iptables -t nat -I PREROUTING -i "$NET_IFACE" -p udp --dport 1:65535 -j DNAT --to-destination :${UDP_PORT}
iptables -D INPUT -p udp --dport ${UDP_PORT} -j ACCEPT 2>/dev/null
iptables -I INPUT -p udp --dport ${UDP_PORT} -j ACCEPT
iptables -D INPUT -p udp --dport 1:65535 -j ACCEPT 2>/dev/null
iptables -I INPUT -p udp --dport 1:65535 -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
ufw allow 1:65535/udp >/dev/null 2>&1

# 6. Configurar y arrancar el servicio Systemd
echo -e "${C_YELLOW}[+] Configurando servicio Systemd...${C_NC}"
cat << EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Official by eProxy
After=network.target

[Service]
User=root
Type=simple
WorkingDirectory=$UDP_DIR
ExecStart=$UDP_DIR/udp-custom server -exclude 53,5300,7300,7200
Restart=always
RestartSec=2
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom >/dev/null 2>&1
systemctl restart udp-custom

sleep 1
if systemctl is-active --quiet udp-custom; then
    echo -e "${C_GREEN}[✔] ¡UDP Custom activo y escuchando en el rango 1-65535 (Interno: $UDP_PORT)!${C_NC}"
else
    echo -e "${C_RED}[✘] Error al iniciar el servicio. Verifica con: journalctl -u udp-custom -n 20${C_NC}"
fi
read -p "Presione Enter para regresar..."
