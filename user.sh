#!/bin/bash
# ==========================================
# Módulo: Creación de Cuentas, Protocolos & Banner
# Golbert VPS V5.0 LTS
# ==========================================

C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 👤 ${C_YELLOW}CREACIÓN DE CUENTA & MÉTODOS DISPONIBLES${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

# Pedir usuario
read -p " Ingresa el nombre de usuario: " USERNAME
if [ -z "$USERNAME" ]; then
    echo -e "${C_RED}[X] El nombre de usuario no puede estar vacío.${C_NC}"
    exit 1
fi

# Verificar si ya existe
if id "$USERNAME" &>/dev/null; then
    echo -e "${C_RED}[X] El usuario '$USERNAME' ya existe en el sistema.${C_NC}"
    exit 1
fi

# Pedir contraseña
read -p " Ingresa la contraseña: " PASSWORD
if [ -z "$PASSWORD" ]; then
    echo -e "${C_RED}[X] La contraseña no puede estar vacía.${C_NC}"
    exit 1
fi

# Pedir días de duración (por defecto 30 días)
read -p " Días de vigencia (Ej: 30): " DAYS
[ -z "$DAYS" ] && DAYS=30

# Calcular fecha de expiración
EXPIRES=$(date -d "+$DAYS days" +"%Y-%m-%d")

# Crear usuario en el sistema Linux
useradd -e "$EXPIRES" -s /bin/false -M "$USERNAME" &>/dev/null
echo "$USERNAME:$PASSWORD" | chpasswd &>/dev/null

# Obtener IP y Dominio del servidor
VPS_IP=$(curl -sS ifconfig.me || hostname -I | awk '{print $1}')
DOMAIN=$(cat /root/domain.txt 2>/dev/null || cat /etc/xray/domain 2>/dev/null || echo "$VPS_IP")

# Detectar puertos activos de cada protocolo
PORT_SSH=22
PORT_WS=80
PORT_SSL=443
systemctl is-active --quiet stunnel4 && PORT_SSL=$(grep "accept =" /etc/stunnel/stunnel.conf | awk '{print $3}')

# Detección de puertos personalizados
PORT_UDP="7300"
[ -f /etc/udp/port.txt ] && PORT_UDP=$(cat /etc/udp/port.txt)

PORT_BHTTP=8080
[ -f /etc/bhttp/port.txt ] && PORT_BHTTP=$(cat /etc/bhttp/port.txt)

PORT_HCR=8880
[ -f /etc/hcr/port.txt ] && PORT_HCR=$(cat /etc/hcr/port.txt)

# Enlace de descarga OpenVPN
OVPN_LINK="No configurado"
if [ -f /root/client.ovpn ] || [ -f /var/www/html/client.ovpn ]; then
    OVPN_LINK="http://$DOMAIN/client.ovpn"
fi

# ==========================================
# Configurar el Banner de Conexión Personalizado (/etc/issue.net)
# ==========================================
cat << EOF > /etc/issue.net
==================================================
        🌟 GOLBERT VPS - ACCESO AUTORIZADO 🌟        
==================================================
 👤 Usuario     : $USERNAME
 📅 Vencimiento : $DAYS días ($EXPIRES)
 🌐 Servidor    : $VPS_IP
==================================================
 ¡Conexión establecida correctamente!
 Respete las políticas de uso del servidor.
==================================================
EOF

# Asegurar que SSH lea este banner en las conexiones
if ! grep -q "Banner /etc/issue.net" /etc/ssh/sshd_config; then
    echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
fi

# Mostrar credenciales de acceso detalladas para el cliente
clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " ✅ ${C_GREEN}DATOS DE ACCESO COMPLETOS${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 👤 Usuario      : $USERNAME"
echo -e " 🔑 Contraseña   : $PASSWORD"
echo -e " 📅 Vencimiento  : $DAYS días ($EXPIRES)"
echo -e "${C_CYAN}------------------------------------------------${C_NC}"
echo -e " 🌐 Host / IP    : $VPS_IP"
echo -e " 🎯 Dominio/SNI  : $DOMAIN"
echo -e "${C_CYAN}------------------------------------------------${C_NC}"
echo -e " 🔌 Puertos & Protocolos Activos:"
echo -e "    • SSH Directo  : $PORT_SSH"
echo -e "    • SSH WebSocket: $PORT_WS (Payloads HTTP)"
echo -e "    • SSH SSL/TLS  : $PORT_SSL (Stunnel)"

if systemctl is-active --quiet udp-custom || systemctl is-active --quiet badvpn; then
echo -e "    • UDP Custom   : $PORT_UDP"
fi

if systemctl is-active --quiet bhttp || ss -tulpn | grep -q ":$PORT_BHTTP"; then
echo -e "    • bHTTP Proxy  : $PORT_BHTTP"
fi

if systemctl is-active --quiet hcr || ss -tulpn | grep -q ":$PORT_HCR"; then
echo -e "    • HCR Nativo   : $PORT_HCR"
fi

if systemctl is-active --quiet xray; then
echo -e "    • Xray VLESS/VM: 80 / 443"
fi

echo -e "${C_CYAN}------------------------------------------------${C_NC}"
echo -e " 📂 Perfil OpenVPN:"
echo -e "    • Enlace       : $OVPN_LINK"
echo -e "${C_CYAN}================================================${C_NC}"
read -p " Presiona [Enter] para volver al menú..."
