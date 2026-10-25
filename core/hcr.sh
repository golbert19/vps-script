#!/bin/bash
# ==========================================
# Gestor HCR Nativo (Manager PRO v1.5.2) - PLAIN ONLY
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
HCR_DIR="/etc/vps-manager/hcr"
mkdir -p "$HCR_DIR"

VCPU=$(nproc)
RAM_MB=$(free -m | awk 'NR==2{print $2}')
MEM_HIGH=$((RAM_MB * 60 / 100))
MEM_MAX=$((RAM_MB * 80 / 100))

check_status() {
    if systemctl is-active --quiet hcr-server; then
        ESTADO="${C_GREEN}ON${C_NC}"
    else
        ESTADO="${C_RED}OFF${C_NC}"
    fi
}

install_hcr_plain() {
    clear
    echo -e "${C_YELLOW}[+] Instalando Servidor HCR Plain (Puerto 8880)...${C_NC}"
    apt update -y && apt install -y python3 iptables >/dev/null 2>&1
    
    # ---------------------------------------------------------
    # Motor HCR Oficial (Responde handshake de HTTP Custom)
    # ---------------------------------------------------------
    cat << 'EOF' > "$HCR_DIR/hcr_core.py"
import socket
import threading

PORT = 8880
SSH_PORT = 22

def handle_client(client_socket):
    try:
        # Leer el saludo del HCR (Handshake) de la app HTTP Custom
        initial_data = client_socket.recv(8192)
        
        # Enviar la respuesta oficial HCR para aceptar la conexión
        hcr_response = b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
        client_socket.sendall(hcr_response)

        # Conectar al puerto SSH real localmente
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.connect(('127.0.0.1', SSH_PORT))
        
        if initial_data and not b"HTTP/" in initial_data:
            server_socket.sendall(initial_data)

        def forward(src, dst):
            while True:
                try:
                    data = src.recv(8192)
                    if not data: break
                    dst.sendall(data)
                except:
                    break

        t1 = threading.Thread(target=forward, args=(client_socket, server_socket))
        t2 = threading.Thread(target=forward, args=(server_socket, client_socket))
        t1.daemon = True
        t2.daemon = True
        t1.start()
        t2.start()
        t1.join()
        t2.join()
    except:
        pass
    finally:
        client_socket.close()

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', PORT))
    server.listen(1024)
    print(f"HCR Plain Core escuchando en puerto {PORT}")
    while True:
        client, addr = server.accept()
        threading.Thread(target=handle_client, args=(client,)).start()

if __name__ == '__main__':
    main()
EOF

    chmod +x "$HCR_DIR/hcr_core.py"
    iptables -I INPUT -p tcp --dport 8880 -j ACCEPT
    iptables-save > /etc/iptables.up.rules 2>/dev/null

    cat << EOF > /etc/systemd/system/hcr-server.service
[Unit]
Description=HCR Native Server Plain
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
    
    clear
    echo -e "${C_GREEN}[✔] ¡Motor HCR Plain (Puerto 8880) Instalado y Activo!${C_NC}"
    echo -e "En HTTP Custom usa el modo: ${C_YELLOW}HCR (Sin TLS)${C_NC}"
    read -p "Presione Enter para regresar..."
}

while true; do
    check_status
    clear
    echo -e "${C_YELLOW}======================================================${C_NC}"
    echo -e "${C_CYAN}    GESTOR HCR NATIVO (MANAGER PRO v1.5.2)            ${C_NC}"
    echo -e "${C_YELLOW}======================================================${C_NC}"
    echo -e ""
    echo -e "Estado Principal: $ESTADO"
    echo -e "Configuración: ${C_CYAN}TCP | Frame | Poll${C_NC}"
    echo -e "Puertos HCR adicionales:"
    echo -e " - Ninguno"
    echo -e "${C_CYAN}AUTO-TUNE: BALANCED+ | CPU $VCPU vCPU | RAM $RAM_MB MB${C_NC}"
    echo -e "${C_GREEN}Recursos: NOFILE 65536 | Tasks 2048 | MemMax ${MEM_MAX}M${C_NC}"
    echo -e ""
    echo -e "${C_RED}──────────────────────────────────────────────────────${C_NC}"
    echo -e "${C_GREEN}[1] > Instalación rápida HCR Plain :8880 [16384 / 8s]${C_NC}"
    echo -e "[2] > Estado completo HCR"
    echo -e "${C_CYAN}[3] > Reiniciar HCR principal${C_NC}"
    echo -e "[4] > Ver registros HCR"
    echo -e "${C_RED}[5] > Desinstalar HCR completo${C_NC}"
    echo -e "${C_RED}[0] > Volver${C_NC}"
    echo -e "${C_RED}──────────────────────────────────────────────────────${C_NC}"
    
    read -p "Opción: " hcr_opt
    case $hcr_opt in
        1) install_hcr_plain ;;
        2) systemctl status hcr-server --no-pager; read -p "Enter..." ;;
        3) systemctl restart hcr-server; echo -e "${C_GREEN}Reiniciado.${C_NC}"; sleep 1 ;;
        4) journalctl -u hcr-server -n 20 --no-pager; read -p "Enter..." ;;
        5) 
           systemctl stop hcr-server; systemctl disable hcr-server
           rm -f /etc/systemd/system/hcr-server.service
           systemctl daemon-reload
           echo -e "${C_RED}HCR Desinstalado.${C_NC}"; sleep 1 ;;
        0) break ;;
        *) echo -e "${C_RED}[!] Opción inválida.${C_NC}"; sleep 1 ;;
    esac
done
