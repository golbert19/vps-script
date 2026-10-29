#!/bin/bash
# ==========================================
# Módulo: Escudo Anti-DDoS y Optimización de Red
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}       ESCUDO ANTI-DDOS Y FIREWALL BÁSICO       ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

echo -e "${C_YELLOW}[+] Aplicando protección en el Kernel (sysctl)...${C_NC}"
cat << EOF > /etc/sysctl.d/99-anti-ddos.conf
# 1. Protección contra ataques SYN Flood (Saturación de conexiones TCP)
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2

# 2. Ignorar Pings falsos y de Broadcast (Smurf Attacks)
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# 3. Protección contra IP Spoofing (Falsificación de IP)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# 4. Desactivar redirecciones ICMP (Evita alteración de rutas)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
EOF
sysctl -p /etc/sysctl.d/99-anti-ddos.conf >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Aplicando reglas IPTables Anti-DDoS...${C_NC}"

# A. Bloquear paquetes malformados o inválidos instantáneamente
iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP

# B. Bloquear paquetes nuevos que no inician con SYN (Escaneos furtivos)
iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP

# C. Limitar Ping (ICMP) a 1 por segundo para evitar Ping of Death
iptables -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT
iptables -A INPUT -p icmp -j DROP

# D. Anti-Fuerza Bruta en SSH (Puerto 22): Máximo 10 intentos por minuto por IP
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 10 -j DROP

iptables-save > /etc/iptables.up.rules 2>/dev/null
netfilter-persistent save >/dev/null 2>&1

echo -e "${C_GREEN}[✔] ¡Protección Anti-DDoS (Software) activada con éxito!${C_NC}"
echo -e "Tu VPS ahora descartará tráfico basura y bloqueará fuerza bruta de forma silenciosa."
read -p "Presiona Enter para regresar..."
