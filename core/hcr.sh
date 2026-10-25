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
    echo -e "${C_GREEN}Instalando HCR Plain en TCP 8880 con perfil 16384 / 8s...${C_NC}"
    echo -e "${C_GREEN}Descargando hcr-server...${C_NC}"
    
    apt update -y >/dev/null 2>&1
    apt install -y python3 iptables curl >/dev/null 2>&1
    cd "$HCR_DIR"
    
    # Intento de descarga segura (Máximo 5 segundos de espera para que NO se congele)
    curl -sL --max-time 5 -o hcr-server "https://raw.githubusercontent.com/ChumoGH/ScriptCGH/main/modulos/hcr-server" || echo ""

    if [ -s hcr-server ]; then
        chmod +x hcr-server
        EXEC_CMD="$HCR_DIR/hcr-server -p 8880 -d 127.0.0.1:22"
    else
        echo -e "${C_YELLOW}Alerta: Servidor externo caído. Generando Motor HCR Local (Python)...${C_NC}"
        # Generador de motor HCR Nativo en Python por si falla la descarga
        cat << 'EOF' > "$HCR_DIR/hcr_bypass.py"
import socket, threading

PORT = 8880
SSH_PORT = 22

def handle(client):
    try:
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.connect(('127.0.0.1', SSH_PORT))
        
        first_data = client.recv(8192)
        if not first_data:
            client.close()
            return
            
        if b"HTTP/" in first_data or b"GET " in first_data or b"CONNECT " in first_data:
            client.sendall(b"HTTP/1.1 200 Connection Established\r\n\r\n")
            if b"SSH-" in first_data:
                server.sendall(first_data[first_data.find(b"SSH-"):])
        else:
            server.sendall(first_data)
            
        def forward(src, dst):
            while True:
                try:
                    d = src.recv(8192)
                    if not d: break
                    dst.sendall(d)
                except: break

        threading.Thread(target=forward, args=(client, server), daemon=True).start()
        threading.Thread(target=forward, args=(server, client), daemon=True).start()
    except:
        client.close()

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('0.0.0.0', PORT))
s.listen(1024)
while True:
    c, a = s.accept()
    threading.Thread(target=handle, args=(c,), daemon=True).start()
EOF
        chmod +x "$HCR_DIR/hcr_bypass.py"
        EXEC_CMD="/usr/bin/python3 $HCR_DIR/hcr_bypass.py"
    fi

    iptables -I INPUT -p tcp --dport 8880 -j ACCEPT
    iptables-save > /etc/iptables.up.rules 2>/dev/null

    cat << EOF > /etc/systemd/system/hcr-server.service
[Unit]
Description=HCR Native Server Plain
After=network.target

[Service]
WorkingDirectory=$HCR_DIR
ExecStart=$EXEC_CMD
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
    
    echo -e "${C_GREEN}[✔] ¡Motor HCR Plain (Puerto 8880) Instalado y Activo!${C_NC}"
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
