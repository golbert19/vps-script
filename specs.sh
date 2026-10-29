#!/bin/bash
# ==========================================
# Módulo: Especificaciones y Capacidad del VPS
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'; C_BLUE='\033[1;34m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 💻        ESPECIFICACIONES DEL SISTEMA         💻"
echo -e "${C_CYAN}================================================${C_NC}"

# Recopilar información de hardware
OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
KERNEL_VER=$(uname -r)
ARCH=$(uname -m)
HOSTNAME=$(hostname)
UPTIME=$(uptime -p | sed 's/up //')
CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -n1 | cut -d':' -f2 | xargs)
CPU_CORES=$(nproc)
CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}')
RAM_TOTAL=$(free -m | awk 'NR==2{print $2}')
RAM_USED=$(free -m | awk 'NR==2{print $3}')
RAM_FREE=$(free -m | awk 'NR==2{print $4}')
RAM_PERC=$(free -m | awk 'NR==2{printf "%d", $3*100/$2}')
DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
DISK_USED=$(df -h / | awk 'NR==2{print $3}')
DISK_FREE=$(df -h / | awk 'NR==2{print $4}')
DISK_PERC=$(df -h / | awk 'NR==2{print $5}')
PUBLIC_IP=$(curl -sS ifconfig.me || echo "No disponible")

echo -e " ${C_YELLOW}🔹 INFORMACIÓN GENERAL:${C_NC}"
echo -e " Hostname    : $HOSTNAME"
echo -e " Sistema     : $OS_NAME ($ARCH)"
echo -e " Kernel      : $KERNEL_VER"
echo -e " Tiempo Act. : $UPTIME"
echo -e " IP Pública  : $PUBLIC_IP"

echo -e "\n ${C_YELLOW}🔹 PROCESADOR (CPU):${C_NC}"
echo -e " Modelo      : $CPU_MODEL"
echo -e " Núcleos     : $CPU_CORES Cores"
echo -e " Uso Actual  : $CPU_LOAD"

echo -e "\n ${C_YELLOW}🔹 MEMORIA RAM:${C_NC}"
echo -e " Total       : ${RAM_TOTAL} MB"
echo -e " En uso      : ${RAM_USED} MB (${RAM_PERC}%)"
echo -e " Disponible  : ${RAM_FREE} MB"

echo -e "\n ${C_YELLOW}🔹 ALMACENAMIENTO (DISCO /):${C_NC}"
echo -e " Total       : $DISK_TOTAL"
echo -e " Usado       : $DISK_USED ($DISK_PERC)"
echo -e " Libre       : $DISK_FREE"

echo -e "${C_CYAN}================================================${C_NC}"
read -p " Presiona Enter para regresar al menú..."
