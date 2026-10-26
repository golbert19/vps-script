#!/bin/bash
# ==========================================
# Módulo: BHTTP Proxy Híbrido (Go Nativo)
# RFC 9292 + WebSocket Fallback
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
BHTTP_DIR="/etc/vps-manager/bhttp"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}   INSTALADOR BHTTP GOLANG (PUERTO DINÁMICO)    ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

read -p "Ingresa el puerto para BHTTP [Por defecto 8080]: " INPUT_PORT
BHTTP_PORT=${INPUT_PORT:-8080}
mkdir -p /etc/vps-manager
echo "$BHTTP_PORT" > /etc/vps-manager/bhttp_port

echo -e "${C_YELLOW}[+] Instalando Golang y dependencias...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y golang iptables net-tools psmisc ufw >/dev/null 2>&1

systemctl stop bhttp.service >/dev/null 2>&1
fuser -k ${BHTTP_PORT}/tcp >/dev/null 2>&1

mkdir -p "$BHTTP_DIR"
cd "$BHTTP_DIR"
rm -f go.mod go.sum bhttp-server main.go

echo -e "${C_YELLOW}[+] Descargando librería oficial openpcc/bhttp...${C_NC}"
go mod init bhttp-server >/dev/null 2>&1
go get github.com/openpcc/bhttp >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Compilando Motor Híbrido (BHTTP + WebSocket)...${C_NC}"
cat << EOF > main.go
package main

import (
	"bufio"
	"context"
	"io"
	"log"
	"net"
	"net/http"

	"github.com/openpcc/bhttp"
)

func main() {
	listener, err := net.Listen("tcp", ":$BHTTP_PORT")
	if err != nil {
		log.Fatal(err)
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

	sshConn, err := net.Dial("tcp", "127.0.0.1:22")
	if err != nil {
		return
	}
	defer sshConn.Close()

	// Leer el primer byte para identificar el protocolo
	reader := bufio.NewReader(conn)
	peek, err := reader.Peek(1)
	if err != nil {
		return
	}

	// Indicadores BHTTP RFC 9292 (0, 1, 2, 3)
	if peek[0] >= 0 && peek[0] <= 3 {
		decoder := &bhttp.RequestDecoder{}
		req, err := decoder.DecodeRequest(context.Background(), reader)
		if err != nil {
			return
		}
		go io.Copy(sshConn, req.Body)

		resp := &http.Response{
			StatusCode: 200,
			Proto:      "HTTP/1.1",
			ProtoMajor: 1,
			ProtoMinor: 1,
			Header:     make(http.Header),
			Body:       sshConn,
		}
		encoder := &bhttp.ResponseEncoder{}
		msg, err := encoder.EncodeResponse(resp)
		if err != nil {
			return
		}
		io.Copy(conn, msg)
	} else {
		// Fallback para HTTP Payload / WebSocket tradicional
		if peek[0] != 'S' {
			conn.Write([]byte("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"))
		}
		go io.Copy(sshConn, reader)
		io.Copy(conn, sshConn)
	}
}
EOF

go build -o bhttp-server main.go

iptables -D INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT 2>/dev/null
iptables -I INPUT -p tcp --dport $BHTTP_PORT -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null
ufw allow ${BHTTP_PORT}/tcp >/dev/null 2>&1

cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=BHTTP Hybrid Server (Port $BHTTP_PORT)
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

IP_VPS=\$(curl -s ipv4.icanhazip.com)
clear
echo -e "${C_GREEN}[✔] ¡Proxy BHTTP instalado y operando en puerto $BHTTP_PORT!${C_NC}"
read -p "Presione Enter para regresar..."
