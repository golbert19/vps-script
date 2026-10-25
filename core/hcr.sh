#!/bin/bash
# ==========================================
# Gestor HCR Nativo (Manager PRO v1.5.2)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
HCR_DIR="/etc/vps-manager/hcr"
mkdir -p "$HCR_DIR"

# Cálculo de Auto-Tune (CPU/RAM)
VCPU=$(nproc)
RAM_MB=$(free -m | awk 'NR==2{print $2}')
MEM_HIGH=$((RAM_MB * 60 / 100))
MEM_MAX=$((RAM_MB * 80 / 100))

# Verificar estado
check_status() {
    if systemctl is-active --quiet hcr-server; then
        ESTADO="${C_GREEN}ON${C_NC}"
    else
        ESTADO="${C_RED}OFF${C_NC}"
    fi
}

install_hcr() {
    clear
    echo -e "${C_YELLOW}[+] Instalando HCR Nativo en puerto 8880...${C_NC}"
    apt update -y && apt install -y python3 iptables >/dev/null 2>&1
    
    # Motor HCR en Python (Multiplexor TCP optimizado)
    cat << 'EOF' > "$HCR_DIR/hcr_core.py"
import socket, threading
PORT = 8880
SSH_PORT = 22
def handle(client):
    try:
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.connect(('127.0.0.1', SSH_PORT))
        def forward(s, d):
            while True:
                data = s.recv(8192)
                if not data: break
                d.sendall(data)
        threading.Thread(target=forward, args=(client, server)).start()
        threading.Thread(target=forward, args=(server, client)).start()
    except:
        client.close()
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('0.0.0.0', PORT))
server.listen(1024)
while True:
    c, a = server.accept()
    threading.Thread(target=handle, args=(c,)).start()
EOF

    iptables -I INPUT -p tcp --dport 8880 -j ACCEPT
    iptables-save > /etc/iptables.up.rules 2>/dev/null

    cat << EOF > /etc/systemd/system/hcr-server.service
[Unit]
Description=HCR Native Server PRO
After=network.target

[Service]
ExecStart=/usr/bin/python3 $HCR_DIR/hcr_core.py
Restart=always
LimitNOFILE=65536
MemoryHigh=${MEM_HIGH}M
MemoryMax=${MEM_MAX}M
TasksMax=2048

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable hcr-server >/dev/null 2>&1
    systemctl restart hcr-server
    echo -e "${C_GREEN}[✔] HCR Plain instalado exitosamente en el puerto 8880.${C_NC}"
    read -p "Presione Enter..."
}

while true; do
    check_status
    clear
    echo -e "${C_YELLOW}======================================================${C_NC}"
    echo -e "${C_CYAN}    GESTOR HCR NATIVO (MANAGER PRO v1.5.2)${C_NC}"
    echo -e "${C_YELLOW}======================================================${C_NC}\n"
    
    echo -e "Estado Principal: $ESTADO"
    echo -e "Configuración: ${C_CYAN}TCP \vert{} Frame \vert{} Poll${C_NC}"
    echo -e "Puertos HCR adicionales:\n - Ninguno"
    echo -e "${C_CYAN}AUTO-TUNE: BALANCED+ \vert{} CPU$VCPU vCPU | RAM $RAM_MB MB \vert{} Listeners 1${C_NC}"
    echo -e "${C_GREEN}Recursos/listener: NOFILE 65536 \vert{} Tasks 2048 \vert{} MemoryHigh${MEM_HIGH}M | MemoryMax ${MEM_MAX}M${C_NC}\n"
    
    echo -e "${C_RED}──────────────────────────────────────────────────────${C_NC}"
    echo -e "${C_GREEN}[1] > Instalación rápida HCR Plain :8880 [16384 / 8s]${C_NC}"
    echo -e "[2] > Instalación personalizada principal (Plain/TLS/Auto)"
    echo -e "[3] > Cambiar puerto HCR principal"
    echo -e "[4] > Cambiar transport HCR principal"
    echo -e "${C_GREEN}[5] > Agregar puerto HCR adicional [LISTENER REAL]${C_NC}"
    echo -e "[6] > Eliminar puerto HCR adicional"
    echo -e "[7] > Ver puertos HCR activos"
    echo -e "[8] > Abrir puerto TCP solo en firewall"
    echo -e "[9] > Cerrar puerto TCP solo en firewall"
    echo -e "[10]> Estado completo HCR"
    echo -e "${C_CYAN}[11]> Reiniciar HCR principal + extras${C_NC}"
    echo -e "[12]> Ver registros HCR"
    echo -e "${C_RED}[13]> Desinstalar HCR completo${C_NC}"
    echo -e "${C_CYAN}[14]> Recalcular AUTO-TUNE CPU/RAM${C_NC}"
    echo -e "${C_RED}[0] > Volver${C_NC}"
    echo -e "${C_RED}──────────────────────────────────────────────────────${C_NC}"
    
    read -p "Opción: " hcr_opt
    case $hcr_opt in
        1) install_hcr ;;
        11) systemctl restart hcr-server; echo -e "${C_GREEN}Reiniciado.${C_NC}"; sleep 1 ;;
        13) systemctl stop hcr-server; systemctl disable hcr-server; rm -f /etc/systemd/system/hcr-server.service; systemctl daemon-reload; echo -e "${C_RED}Desinstalado.${C_NC}"; sleep 1 ;;
        0) break ;;
        *) echo -e "${C_YELLOW}Función en desarrollo...${C_NC}"; sleep 1 ;;
    esac
done
