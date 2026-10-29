#!/bin/bash
C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_NC='\033[0m'
clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🔍 ${C_YELLOW}MONITOR DE PUERTOS Y SERVICIOS ACTIVOS${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
printf "%-10s %-15s %-20s\n" "PROTO" "PUERTO" "SERVICIO / PROCESO"
echo -e "${C_CYAN}------------------------------------------------${C_NC}"

netstat -tulnp 2>/dev/null | grep LISTEN | while read -r line; do
    proto=$(echo $line | awk '{print $1}')
    addr=$(echo $line | awk '{print $4}')
    port=$(echo $addr | awk -F':' '{print $NF}')
    proc=$(echo $line | awk '{print $NF}')
    printf "%-10s %-15s %-20s\n" "$proto" "$port" "$proc"
done

echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presiona Enter para regresar..."
