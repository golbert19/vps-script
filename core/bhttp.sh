#!/bin/bash
# ==========================================
# Módulo: BHTTP Proxy (HTTP Custom) - Puerto 8080
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}[+] Instalando y configurando BHTTP Proxy (Puerto 8080)...${C_NC}"

apt update -y && apt install -y python3 iptables >/dev/null 2>&1

BHTTP_DIR="/etc/vps-manager/bhttp"
mkdir -p "$BHTTP_DIR"

# Crear el script del servidor BHTTP en Python (Ligero, rápido y compatible con HTTP Custom)
cat << 'EOF' > "$BHTTP_DIR/bhttp_server.py"
import http.server
import socketserver
import threading

PORT = 8080

class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    def do_CONNECT(self):
        self.send_response(200, "Connection Established")
        self.end_headers()
        try:
            host, port = self.path.split(':')
            port = int(port)
            server_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server_sock.connect((host, port))
            
            self.connection.setblocking(False)
            server_sock.setblocking(False)
            
            def forward(source, destination):
                while True:
                    try:
                        data = source.recv(8192)
                        if not data:
                            break
                        destination.sendall(data)
                    except:
                        break

            t1 = threading.Thread(target=forward, args=(self.connection, server_sock))
            t2 = threading.Thread(target=forward, args=(server_sock, self.connection))
            t1.daemon = True
            t2.daemon = True
            t1.start()
            t2.start()
            t1.join()
        except Exception as e:
            pass

    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"BHTTP Proxy Golbert Running Successfully!")

with socketserver.ThreadingTCPServer(("0.0.0.0", PORT), ProxyHandler) as httpd:
    print(f"BHTTP Proxy corriendo en puerto {PORT}")
    httpd.serve_forever()
EOF

chmod +x "$BHTTP_DIR/bhttp_server.py"

# Abrir el puerto 8080 en Iptables
iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null

# Crear servicio Systemd con el nombre exacto 'bhttp'
cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=BHTTP Proxy Service for HTTP Custom
After=network.target

[Service]
ExecStart=/usr/bin/python3 $BHTTP_DIR/bhttp_server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bhttp >/dev/null 2>&1
systemctl restart bhttp

IP_VPS=$(curl -s ipv4.icanhazip.com)
clear
echo -e "${C_GREEN}[✔] ¡BHTTP Proxy instalado y activo con éxito!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 Host / IP : $IP_VPS"
echo -e " 🎯 Puerto    : 8080 (Ideal para HTTP Custom)"
echo -e "${C_CYAN}================================================${NC}"
read -p "Presione Enter para regresar..."
