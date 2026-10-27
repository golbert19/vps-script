#!/bin/bash
# ==========================================
# Módulo: UDP Custom (Oficial eProxy Devs)
# Soporta rango 1-65535 + Puerto 25000 Activo
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
UDP_DIR="/etc/vps-manager/udp"
UDP_ROOT="/root/udp"
UDP_PORT=25000

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   INSTALADOR UDP CUSTOM (RANGO 1-65535)        ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

# 1. Detener servicio previo y limpiar directorios
systemctl stop udp-custom >/dev/null 2>&1
fuser -k ${UDP_PORT}/udp >/dev/null 2>&1
rm -rf "$UDP_ROOT" "$UDP_DIR"
mkdir -p "$UDP_ROOT" "$UDP_DIR"

# 2. Descargar binario oficial desde espejos activos verificados
echo -e "${C_YELLOW}[+] Descargando binario oficial UDP Custom...${C_NC}"
URLS=(
    "https://github.com/Haris131/UDP-Custom/raw/main/udp-custom-linux-amd64"
    "https://github.com/http-custom/udp-custom/raw/main/udp-custom-linux-amd64"
    "https://github.com/feely666/udp-custom/raw/main/udp-custom-linux-amd64"
    "https://github.com/powermx/httpcustomudp/raw/main/udp-custom"
)

for url in "${URLS[@]}"; do
    wget --no-check-certificate -qO "$UDP_ROOT/udp-custom" "$url"
    if [ "$(stat -c%s "$UDP_ROOT/udp-custom" 2>/dev/null || echo 0)" -gt 1000000 ]; then
        echo -e "${C_GREEN}[✔] Binario descargado correctamente.${C_NC}"
        break
    fi
done

if [ "$(stat -c%s "$UDP_ROOT/udp-custom" 2>/dev/null || echo 0)" -lt 1000000 ]; then
    echo -e "${C_RED}[✘] Error crítico: No se pudo descargar el binario de UDP Custom.${C_NC}"
    read -p "Presione Enter para regresar..."
    exit 1
fi

chmod +x "$UDP_ROOT/udp-custom"

# 3. Crear config.json en /root/udp y sincronizar con /etc/vps-manager/udp
echo -e "${C_YELLOW}[+] Generando archivo config.json en puerto $UDP_PORT...${C_NC}"
cat << EOF > "$UDP_ROOT/config.json"
{
  "listen": ":${UDP_PORT}",
  "stream_buffer": 33554432,
  "receive_buffer": 83886080,
  "auth": {
    "mode": "passwords"
  }
}
EOF
chmod 644 "$UDP_ROOT/config.json"

# Copiar binarios y config a la ruta del panel para mantener compatibilidad
cp -f "$UDP_ROOT/udp-custom" "$UDP_DIR/udp-custom"
cp -f "$UDP_ROOT/config.json" "$UDP_DIR/config.json"
chmod +x "$UDP_DIR/udp-custom"

# 4. Ajustar encriptación PAM a SHA512 (compatibilidad Ubuntu 22.04/24.04)
echo -e "${C_YELLOW}[+] Ajustando compatibilidad de contraseñas PAM...${C_NC}"
if [ -f /etc/pam.d/common-password ]; then
    sed -i 's/yescrypt/sha512/g' /etc/pam.d/common-password
fi
if [ -f /etc/login.defs ]; then
    sed -i 's/^ENCRYPT_METHOD.*/ENCRYPT_METHOD SHA512/g' /etc/login.defs
fi

# 5. Configurar Firewall y redirección NAT del rango 1-65535 al puerto 25000
echo -e "${C_YELLOW}[+] Configurando redirección de puertos 1-65535 en Firewall...${C_NC}"
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
NET_IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

# Limpiar reglas anteriores y excluir puertos críticos (DNS y BadVPN)
iptables -t nat -F PREROUTING 2>/dev/null
iptables -t nat -A PREROUTING -i "$NET_IFACE" -p udp -m multiport --dports 53,5300,7200,7300,${UDP_PORT} -j ACCEPT
iptables -t nat -A PREROUTING -i "$NET_IFACE" -p udp --dport 1:65535 -j REDIRECT --to-ports ${UDP_PORT}
iptables -I INPUT -p udp --dport ${UDP_PORT} -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
ufw allow ${UDP_PORT}/udp >/dev/null 2>&1
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
WorkingDirectory=$UDP_ROOT
ExecStart=$UDP_ROOT/udp-custom server -exclude 53,5300,7300,7200
Restart=always
RestartSec=2s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom >/dev/null 2>&1
systemctl restart udp-custom

sleep 2
if systemctl is-active --quiet udp-custom; then
    echo -e "${C_GREEN}[✔] ¡UDP Custom ACTIVO en el puerto $UDP_PORT y rango 1-65535!${C_NC}"
else
    echo -e "${C_RED}[✘] Error al iniciar el servicio:${C_NC}"
    journalctl -u udp-custom -n 10 --no-pager
fi
read -p "Presione Enter para regresar..."
