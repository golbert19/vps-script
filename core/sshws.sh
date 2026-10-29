#!/bin/bash
# ==========================================
# Módulo: SSH WebSocket + SSL (Proxy para Payloads)
# Versión Optimizada para Golbert VPS V5.0
# ==========================================

clear
echo -e "\033[1;36m[+] Instalando y actualizando dependencias (Python3 y Stunnel4)...\033[0m"
apt update -y && apt install -y python3 stunnel4 >/dev/null 2>&1

mkdir -p /etc/vps-manager/core /root/core

# 1. Crear el Proxy Python Optimizado (Escucha en puerto 80 con manejo de excepciones robusto)
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

        # Responder correctamente al Handshake del Payload WebSocket
        response = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
        client_socket.sendall(response.encode('utf-8'))

        # Conectar al servicio SSH local (puerto 22)
        ssh_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh_socket.connect(('127.0.0.1', 22))

        # Hilos concurrentes bidireccionales con control de errores por socket
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
            if not data:
                break
            dst.sendall(data)
    except Exception:
        pass
    finally:
        try:
            src.close()
        except:
            pass
        try:
            dst.close()
        except:
            pass

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', 80))
    server.listen(500)
    print("Proxy WebSocket multiconexión escuchando en el puerto 80...")
    while True:
        try:
            client, addr = server.accept()
            client_thread = threading.Thread(target=handle_client, args=(client,))
            client_thread.daemon = True
            client_thread.start()
        except Exception:
            continue

if __name__ == '__main__':
    main()
EOF

# Copiar también al directorio /root/core para compatibilidad total con el panel principal
cp -f /etc/vps-manager/core/proxy.py /root/core/proxy.py
chmod +x /etc/vps-manager/core/proxy.py /root/core/proxy.py

# 2. Crear o mantener certificado SSL seguro para Stunnel4
if [ ! -f /etc/stunnel/stunnel.pem ]; then
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj "/C=PE/ST=Lima/L=Lima/O=Golbert/CN=golbertvps.online" \
        -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem >/dev/null 2>&1
fi
chmod 600 /etc/stunnel/stunnel.pem

# 3. Configuración de Stunnel4 (Optimizada para estabilidad en puertos 443 -> 80)
cat << 'EOF' > /etc/stunnel/stunnel.conf
pid = /var/run/stunnel4/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ws-ssl]
accept = 443
connect = 127.0.0.1:80
EOF

sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4 2>/dev/null

# 4. Crear Servicio Systemd robusto para el Proxy Python
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

# 5. Liberar puertos de manera segura, recargar daemons y reiniciar servicios
fuser -k 80/tcp 2>/dev/null
fuser -k 443/tcp 2>/dev/null

systemctl daemon-reload
systemctl enable ws-python
systemctl restart ws-python
systemctl restart stunnel4

echo -e "\n\033[1;32m[✔] SSH WebSocket (Puerto 80) y SSL (Puerto 443) optimizados e instalados con éxito.\033[0m"
sleep 2
