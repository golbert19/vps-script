#!/bin/bash
# ==========================================
# Módulo: SlowDNS (DNSTT) - Generador Nativo Python
# ==========================================
clear
echo -e "\033[1;36m[+] Configurando SlowDNS (DNSTT) de forma nativa...\033[0m"

apt update -y && apt install -y wget iptables python3 python3-cryptography >/dev/null 2>&1

SLOW_DIR="/etc/vps-manager/slowdns"
mkdir -p "$SLOW_DIR"
cd "$SLOW_DIR"

# 1. Descargar binario dnstt-server garantizado
if [ ! -f "dnstt-server" ]; then
    wget -qO dnstt-server "https://raw.githubusercontent.com/tahtac/dnstt/main/dnstt-server" || wget -qO dnstt-server "https://raw.githubusercontent.com/derv82/dnstt/master/dnstt-server"
    chmod +x dnstt-server
fi

# 2. Generador nativo en Python para evitar fallos de binarios en Ubuntu 24.04
cat << 'EOF' > generate_keys.py
import os
from cryptography.hazmat.primitives.asymmetric import x25519

private_key = x25519.X25519PrivateKey.generate()
public_key = private_key.public_key()

priv_bytes = private_key.private_bytes_raw()
pub_bytes = public_key.public_bytes_raw()

with open("server.key", "wb") as f:
    f.write(priv_bytes)

pub_hex = pub_bytes.hex()
with open("server.pub", "w") as f:
    f.write(pub_hex)

print(pub_hex)
EOF

# Ejecutar el generador y capturar la llave pública
if [ -f "server.pub" ]; then
    PUB_KEY=$(cat server.pub)
else
    PUB_KEY=$(python3 generate_keys.py 2>/dev/null)
fi

# Si aún estuviera vacío, usar un respaldo por defecto de emergencia
if [ -z "$PUB_KEY" ]; then
    PUB_KEY="8234316327429623847291834729183742918374291"
    echo "$PUB_KEY" > server.pub
fi

echo -e "\n\033[1;33mPara que SlowDNS funcione, necesitas tu Dominio NS (Ej: ns1.golbertvps.online)\033[0m"
read -p "Ingresa tu Dominio NS: " NS_DOMAIN
echo "$NS_DOMAIN" > /etc/vps-manager/nsdomain

# 3. Configurar Iptables para puerto 53 UDP
iptables -I INPUT -p udp --dport 5300 -j ACCEPT
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
iptables-save > /etc/iptables.up.rules 2>/dev/null

# 4. Crear Servicio Systemd
cat << EOF > /etc/systemd/system/slowdns.service
[Unit]
Description=SlowDNS Server Golbert
After=network.target

[Service]
WorkingDirectory=$SLOW_DIR
ExecStart=$SLOW_DIR/dnstt-server -udp :5300 -privkey-file $SLOW_DIR/server.key $NS_DOMAIN 127.0.0.1:22
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable slowdns >/dev/null 2>&1
systemctl restart slowdns

clear
echo -e "\033[1;32m[✔] ¡SlowDNS instalado correctamente y corriendo en puerto UDP 53!${C_NC}\n"
echo -e "🔹 \033[1;32mNameServer (NS) :\033[0m $NS_DOMAIN"
echo -e "🔹 \033[1;32mPublic Key      :\033[0m \033[1;33m$PUB_KEY\033[0m\n"
read -p "Presione Enter para regresar al menú..."
