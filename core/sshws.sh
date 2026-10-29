#!/bin/bash
# ==========================================
# Módulo: SSH WebSocket + SSL (Instalar / Desinstalar)
# Golbert VPS V5.0 LTS
# ==========================================

clear
echo -e "\033[1;36m================================================\033[0m"
echo -e " \033[1;33mSSH WEBSOCKET & SSL MANAGER\033[0m"
echo -e "\033[1;36m================================================\033[0m"
echo -e " 1. 📥 Instalar / Actualizar WebSocket + SSL"
echo -e " 2. ❌ Desinstalar WebSocket + SSL (Liberar puertos)"
echo -e " 0. 🚪 Volver"
echo -e "\033[1;36m================================================\033[0m"
read -p " Selecciona una opción: " opt

case $opt in
    1)
        echo -e "\n\033[1;33m[+] Instalando Python y Stunnel4...\033[0m"
        apt update -y && apt install -y python3 stunnel4 >/dev/null 2>&1

        mkdir -p /etc/vps-manager/core /root/core

        # 1. Crear el Proxy Python Optimizado (Escucha en puerto 80)
        cat << 'EOF' > /etc/vps-manager/core/proxy.py
import socket
import threading
import sys

def handle_client(client_socket):
    try:
        request = client_socket.recv(1024).decode('utf-8', errors='ignore')
        if not request:
            client_socket.close()
            return

        response = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
        client_socket.sendall(response.encode('utf-8'))

        ssh_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh_socket.connect(('127.0.0.1', 22))

        t1 = threading.Thread(target=transfer, args=(client_socket, ssh_socket))
        t2 = threading.Thread(target=transfer, args=(ssh_socket, client_socket))
        t1.daemon = True
        t2.daemon = True
        t1.start()
        t2.start()
    except Exception:
        client_socket.close()

def transfer(src, dst):
    try:
        while True:
            data = src.recv(8192)
            if not data: break
            dst.sendall(data)
    except Exception:
        pass
    finally:
        try: src.close()
        except: pass
        try: dst.close()
        except: pass

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', 80))
    server.listen(500)
    while True:
        try:
            client, addr = server.accept()
            threading.Thread(target=handle_client, args=(client,)).daemon = True
            client.start() if hasattr(client, 'start') else None # Fix thread start
        except Exception:
            continue

if __name__ == '__main__':
    main()
EOF

        # Copiar para compatibilidad de rutas
        cp -f /etc/vps-manager/core/proxy.py /root/core/proxy.py
        chmod +x /etc/vps-manager/core/proxy.py /root/core/proxy.py

        # 2. Certificado SSL para Stunnel4
        if [ ! -f /etc/stunnel/stunnel.pem ]; then
            openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
                -subj "/C=PE/ST=Lima/L=Lima/O=Golbert/CN=golbertvps.online" \
                -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem >/dev/null 2>&1
        fi
        chmod 600 /etc/stunnel/stunnel.pem

        # 3. Configurar Stunnel4 (Toma el puerto 443 si está libre, o usa 444 si Xray lo ocupa)
        PORT_SSL=443
        if systemctl is-active --quiet xray; then
            PORT_SSL=444
            echo -e "\033[1;33m[!] Xray detectado activo. Stunnel configurado en puerto seguro 443 (vía 444).\033[0m"
        fi

        cat << EOF > /etc/stunnel/stunnel.conf
pid = /var/run/stunnel4/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ws-ssl]
accept = $PORT_SSL
connect = 127.0.0.1:80
EOF

        sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4 2>/dev/null

        # 4. Servicio Systemd
        cat << 'EOF' > /etc/systemd/system/ws-python.service
[Unit]
Description=Proxy Python WebSocket (Golbert VPS)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /etc/vps-manager/core/proxy.py
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

        # Liberar puertos y encender servicios
        fuser -k 80/tcp 2>/dev/null
        systemctl daemon-reload
        systemctl enable ws-python stunnel4
        systemctl restart ws-python stunnel4

        echo -e "\n\033[1;32m[✔] SSH WebSocket (Puerto 80) y SSL (Puerto $PORT_SSL) instalados correctamente.\033[0m"
        sleep 2
        ;;
    2)
        echo -e "\n\033[1;31m[-] Desinstalando SSH WebSocket y Stunnel4...\033[0m"
        systemctl stop ws-python stunnel4 2>/dev/null
        systemctl disable ws-python stunnel4 2>/dev/null
        rm -f /etc/systemd/system/ws-python.service
        rm -f /etc/vps-manager/core/proxy.py /root/core/proxy.py
        systemctl daemon-reload
        fuser -k 80/tcp 2>/dev/null
        echo -e "\n\033[1;32m[✔] WebSocket y SSL desinstalados. Puertos liberados con éxito.\033[0m"
        sleep 2
        ;;
    0)
        exit 0
        ;;
    *)
        echo -e "\n\033[1;31mOpción inválida.\033[0m"
        sleep 1
        ;;
esac
