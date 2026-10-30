#!/bin/bash
# ==========================================
# Instalador SSH WebSocket (Dual Logic) - Golbert VPS
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 ${C_YELLOW}INSTALADOR SSH WEBSOCKET PYTHON (DUAL)${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

DEFAULT_PORT=8080

# 1. VERIFICACIÓN Y ASIGNACIÓN DE PUERTO
while true; do
    read -p " Ingresa el puerto a instalar (Por defecto: $DEFAULT_PORT): " CUSTOM_PORT
    CUSTOM_PORT=${CUSTOM_PORT:-$DEFAULT_PORT}

    if netstat -tuln | grep -qE ":$CUSTOM_PORT\b"; then
        echo -e " ${C_RED}⚠️ Error: El puerto $CUSTOM_PORT ya está siendo usado por otro servicio.${C_NC}"
    else
        echo -e " ${C_GREEN}✅ Puerto $CUSTOM_PORT disponible.${C_NC}"
        PORT=$CUSTOM_PORT
        break
    fi
done

echo -e "\n ${C_YELLOW}⚙️ Instalando y configurando proxy en el puerto $PORT...${C_NC}"

mkdir -p /etc/vps-manager/proxy

# 2. CREACIÓN DEL CÓDIGO PYTHON (Exactamente el mismo que ya funciona)
cat << EOF > /etc/vps-manager/proxy/proxy.py
import socket
import threading
import subprocess

def get_user_expiration(username):
    try:
        chage_out = subprocess.check_output(f"chage -l {username}", shell=True, stderr=subprocess.STDOUT).decode('utf-8')
        for line in chage_out.split('\n'):
            if "Account expires" in line or "La cuenta caduca" in line:
                date_str = line.split(':')[1].strip()
                return date_str if date_str != "never" else "Ilimitado"
        return "Desconocido"
    except:
        return "No encontrado"

def handle_client(client_socket):
    try:
        raw_request = client_socket.recv(4096)
        if not raw_request:
            client_socket.close()
            return

        request_text = raw_request.decode('utf-8', errors='ignore')
        request_lower = request_text.lower()

        ssh_user = None
        for line in request_text.split('\r\n'):
            if line.lower().startswith('x-user:') or line.lower().startswith('ssh-user:'):
                ssh_user = line.split(':')[1].strip()
                break

        ssh_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh_socket.connect(('127.0.0.1', 22))

        if "upgrade: websocket" in request_lower:
            response = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
            if ssh_user:
                exp_date = get_user_expiration(ssh_user)
                banner_html = (
                    f"<br><b><font color='#00FF00'>👤 Usuario : {ssh_user}</font></b><br>"
                    f"<b><font color='#FFFF00'>⏳ Expira  : {exp_date}</font></b><br>"
                    f"<b><font color='#00FFFF'>🛡️ Golbert VPS Premium</font></b><br><br>"
                )
                response += banner_html
        else:
            response = "HTTP/2.0 1299\r\nHost: survey.tigo.com\nContent-Length: 55555555\n\r\n"

        client_socket.sendall(response.encode('utf-8'))

        def transfer(src, dst):
            try:
                while True:
                    data = src.recv(8192)
                    if not data: break
                    dst.sendall(data)
            except:
                pass
            finally:
                try: src.close()
                except: pass
                try: dst.close()
                except: pass

        t1 = threading.Thread(target=transfer, args=(client_socket, ssh_socket))
        t2 = threading.Thread(target=transfer, args=(ssh_socket, client_socket))
        t1.daemon = True
        t2.daemon = True
        t1.start()
        t2.start()
    except:
        try: client_socket.close()
        except: pass

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    # Aquí se inyecta el puerto elegido dinámicamente
    server.bind(('0.0.0.0', ${PORT}))
    server.listen(500) 
    print(f"Proxy Dual iniciado en puerto {${PORT}}...")
    
    while True:
        try:
            client, addr = server.accept()
            t = threading.Thread(target=handle_client, args=(client,))
            t.daemon = True
            t.start()
        except:
            continue

if __name__ == '__main__':
    main()
EOF

# 3. CREACIÓN DEL SERVICIO SYSTEMD
cat << EOF > /etc/systemd/system/ws-python.service
[Unit]
Description=SSH WebSocket Python Proxy (Dual Logic)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/vps-manager/proxy
ExecStart=/usr/bin/python3 /etc/vps-manager/proxy/proxy.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 4. APLICAR CAMBIOS Y ARRANCAR
systemctl daemon-reload
systemctl enable ws-python >/dev/null 2>&1
systemctl restart ws-python

echo -e "\n ${C_GREEN}✅ Instalación completada con éxito.${C_NC}"
echo -e " ${C_CYAN}▶️ El Proxy Dual ahora está escuchando en el puerto: $PORT${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presiona Enter para continuar..."
