mkdir -p /etc/vps-manager/core
cat << 'EOF' > /etc/vps-manager/core/ports.sh
#!/bin/bash
# ==========================================
# Monitor Visual de Puertos - Golbert VPS
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🔍 ${C_YELLOW}ESTADO DE PROTOCOLOS Y PUERTOS${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

# Función para verificar el puerto
check_port() {
    local name="$1"
    local port="$2"
    # Busca el puerto exacto en los servicios que están escuchando
    if netstat -tuln 2>/dev/null | grep -qE ":$port\b"; then
        printf " %-20s : ${C_GREEN}ACTIVO${C_NC}   (Puerto %s)\n" "$name" "$port"
    else
        printf " %-20s : ${C_RED}INACTIVO${C_NC} (Puerto %s)\n" "$name" "$port"
    fi
}

# Lista de chequeo de servicios
check_port "SSH Principal" "22"
check_port "WS HTTP / Dropbear" "80"
check_port "SSL / Trojan" "443"
check_port "Stunnel Proxy" "444"
check_port "Nginx Gateway" "8442"
check_port "Python WS Proxy" "8080"
check_port "Web Panel UI" "8181"
check_port "HCR Server" "8888"
check_port "OpenVPN" "1194"
check_port "BadVPN UDPGW" "7200"
check_port "BadVPN UDPGW" "7300"
check_port "UDP Custom" "2000"
check_port "UDP Custom" "25000"

echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presiona Enter para regresar al menú..."
EOF

chmod +x /etc/vps-manager/core/ports.sh
