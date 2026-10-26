#!/bin/bash
# ==========================================
# Módulo: BHTTP Proxy Server (Compilación Nativa en Go)
# Usa la librería oficial github.com/openpcc/bhttp
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

BHTTP_DIR="/etc/vps-manager/bhttp"
BHTTP_PORT=8080
SSH_PORT=22

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   INSTALADOR BHTTP GOLANG (PUERTO 8080)        ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}[+] Instalando Golang y dependencias de red...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y golang iptables net-tools psmisc ufw >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Deteniendo servicios conflictivos...${C_NC}"
systemctl stop bhttp.service >/dev/null 2>&1
fuser -k ${BHTTP_PORT}/tcp >/dev/null 2>&1

mkdir -p "$BHTTP_DIR"
cd "$BHTTP_DIR"

echo -e "${C_YELLOW}[+] Inicializando entorno Go y descargando librería BHTTP...${C_NC}"
rm -f go.mod go.sum bhttp-server main.go
go mod init bhttp-server >/dev/null 2>&1
go get github.com/openpcc/bhttp >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Escribiendo código fuente del servidor proxy...${C_NC}"
cat << 'EOF' > main.go
package main

import (
	"context"
	"io"
	"log"
	"net"
	"net/http"

	"github.com/openpcc/bhttp"
)

func main() {
	listener, err := net.Listen("tcp", ":8080")
	if err != nil {
		log.Fatal("Error al iniciar puerto 8080:", err)
	}
	for {
		conn, err := listener.Accept()
		if err != nil {
			continue
		}
		go handleConnection(conn)
	}
}

func handleConnection(conn net.Conn) {
	defer conn.Close()
	
	// Decodificación de la solicitud BHTTP del cliente VPN
	decoder := &bhttp.RequestDecoder{}
	req, err := decoder.DecodeRequest(context.Background(), conn)
	if err != nil {
		return
	}

	// Conectar internamente al puerto SSH
	sshConn, err := net.Dial("tcp", "127.0.0.1:22")
	if err != nil {
		return
	}
	defer sshConn.Close()

	// 1. Redirigir el cuerpo de la petición BHTTP hacia el servidor SSH
	go io.Copy(sshConn, req.Body)

	// 2. Preparar la respuesta BHTTP (Longitud indeterminada para streaming)
	resp := &http.Response{
		StatusCode: http.StatusOK,
		Proto:      "HTTP/1.1",
		ProtoMajor: 1,
		ProtoMinor: 1,
		Header:     make(http.Header),
		Body:       sshConn, // El output de SSH se envía como cuerpo de la respuesta
	}
	
	encoder := &bhttp.ResponseEncoder{}
	msg, err := encoder.EncodeResponse(resp)
	if err != nil {
		return
	}

	// Enviar respuesta BHTTP en streaming de vuelta al cliente
	io.Copy(conn, msg)
}
EOF

echo -e "${C_YELLOW}[+] Compilando binario nativo (Esto tomará unos segundos)...${C_NC}"
go build -o bhttp-server main.go

# Reglas de Firewall para asegurar el puerto 8080
iptables -D INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT 2>/dev/null
iptables -I INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
ufw allow ${BHTTP_PORT}/tcp >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Creando servicio Systemd...${C_NC}"
cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=Golbert BHTTP Native Server (Port $BHTTP_PORT)
After=network.target ssh.service

[Service]
Type=simple
User=root
WorkingDirectory=$BHTTP_DIR
ExecStart=$BHTTP_DIR/bhttp-server
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bhttp.service >/dev/null 2>&1
systemctl restart bhttp.service

IP_VPS=$(curl -s ipv4.icanhazip.com)
DOM=$( [ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo "$IP_VPS" )

clear
echo -e "${C_GREEN}[✔] ¡Proxy BHTTP Nativo compilado y activo con éxito!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 Host / IP  : ${C_YELLOW}$DOM${C_NC}"
echo -e " 🎯 Puerto     : ${C_YELLOW}$BHTTP_PORT${C_NC}"
echo -e " ⚙️ Motor      : ${C_YELLOW}Golang (github.com/openpcc/bhttp)${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presione Enter para regresar al menú..."
