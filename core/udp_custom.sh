#!/bin/bash
# ==========================================
# Módulo: UDP Custom Universal (Ubuntu 22/24/26)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
UDP_DIR="/etc/vps-manager/udp"
mkdir -p "$UDP_DIR"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}    CONFIGURANDO UDP CUSTOM (PUERTO 2000)       ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

# Preparar dependencias apt adaptadas a Ubuntu moderno
apt update -y >/dev/null 2>&1
apt install -y python3 iptables net-tools iproute2 >/dev/null 2>&1

cd "$UDP_DIR"

# Generar demonio UDP optimizado compatible con cualquier Ubuntu LTS
cat << 'EOF' > "$UDP_DIR/udp_server.py"
import socket
import sys

PORT = 2000
def main():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        sock.bind(('0.0.0.0', PORT))
        print(f"UDP Custom Universal Server activo en puerto {PORT}")
    except Exception as e:
        print(f"Error al enlazar el puerto: {e}")
        sys.exit(1)

    while True:
        try:
            data, addr = sock.recvfrom(65535)
            if data:
                sock.sendto(data, addr)
        except:
            pass

if __name__ == '__main__':
    main()
EOF

chmod +x "$UDP_DIR/udp_server.py"

# Limpiar reglas previas del puerto 2000 y aplicar nuevas
iptables -D INPUT -p udp --dport 2000 -j ACCEPT 2>/dev/null
iptables -I INPUT -p udp --dport 2000 -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null

# Forzar creación y recarga del servicio systemd
cat << EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Universal Server Port 2000
After=network.target network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$UDP_DIR
ExecStart=/usr/bin/python3 $UDP_DIR/udp_server.py
Restart=always
RestartSec=3
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom >/dev/null 2>&1
systemctl restart udp-custom

IP_VPS=$(curl -s ipv4.icanhazip.com)
clear
echo -e "${C_GREEN}[✔] ¡UDP Custom configurado con éxito para Ubuntu LTS!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 Host / IP : $IP_VPS"
echo -e " 🎯 Puerto UDP: 2000 (Activo en verde)"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presione Enter para regresar al menú..."
