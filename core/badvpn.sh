#!/bin/bash
# ==========================================
# Módulo: BadVPN (UDPGW) para Juegos / Llamadas
# ==========================================
clear
echo -e "\033[1;36m[+] Instalando BadVPN (UDPGW) en el puerto 7300...\033[0m"
apt update -y && apt install -y cmake make gcc g++ unzip zip >/dev/null 2>&1

cd /tmp
wget -qO badvpn.zip https://github.com/ambrop72/badvpn/archive/master.zip
unzip -q badvpn.zip
cd badvpn-master
mkdir build && cd build
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 >/dev/null 2>&1
make >/dev/null 2>&1
cp badvpn-udpgw /usr/local/bin/
chmod +x /usr/local/bin/badvpn-udpgw

cat << EOF > /etc/systemd/system/badvpn.service
[Unit]
Description=BadVPN UDPGW Golbert
After=network.target
[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500 --max-connections-for-client 20 --client-socket-sndbuf 10000
Restart=always
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable badvpn >/dev/null 2>&1
systemctl restart badvpn

echo -e "\033[1;32m[✔] BadVPN instalado y corriendo en el puerto 7300.\033[0m"
read -p "Presione Enter para regresar..."
