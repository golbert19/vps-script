#!/bin/bash
# ==========================================
# Módulo: SSHWS (Proxy WebSocket para SSH)
# ==========================================

clear
echo -e "\033[1;36m[+] Configurando SSH WebSocket (SSHWS)...\033[0m"

apt update -y && apt install -y python3 python3-pip >/dev/null 2>&1

WS_DIR="/etc/vps-manager/core"
mkdir -p "$WS_DIR"

# Crear script de proxy websocket en python
cat << 'EOF' > "$WS_DIR/ws_proxy.py"
import asyncio
import websockets

async def echo(websocket, path):
    async for message in websocket:
        reader, writer = await asyncio.open_connection('127.0.0.1', 22)
        writer.write(message)
        await writer.drain()
        data = await reader.read(8192)
        await websocket.send(data)

async def main():
    server = await websockets.serve(echo, "0.0.0.0", 8080)
    await server.wait_closed()

if asyncio.get_event_loop().run_until_complete(main()):
    pass
EOF

# Crear servicio Systemd para SSHWS en puerto 8080
cat << 'EOF' > /etc/systemd/system/sshws.service
[Unit]
Description=SSH WebSocket Proxy Golbert
After=network.target

[Service]
ExecStart=/usr/bin/python3 /etc/vps-manager/core/ws_proxy.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Instalar librería websockets si no está presente
pip3 install websockets >/dev/null 2>&1

systemctl daemon-reload
systemctl enable sshws
systemctl restart sshws

echo -e "\n\033[1;32m[✔] ¡SSHWS instalado y corriendo en el puerto 8080!\033[0m"
sleep 2
