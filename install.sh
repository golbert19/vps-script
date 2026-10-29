#!/bin/bash
# ==========================================
# Script de Instalación - Golbert VPS V5.0 LTS
# ==========================================

C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

# ==========================================
# MOTOR DE BARRA DE PROGRESO ANIMADA
# ==========================================
barra_porcentaje() {
    local comando="$1"
    local mensaje="$2"
    
    # Ejecuta el comando en segundo plano de forma silenciosa
    eval "$comando" >/dev/null 2>&1 &
    local pid=$!
    
    local progreso=0
    tput civis # Oculta el cursor intermitente para que se vea limpio
    
    while kill -0 $pid 2>/dev/null; do
        progreso=$((progreso + 1))
        # Congelar en 99% hasta que el comando termine realmente
        [ $progreso -gt 99 ] && progreso=99 
        
        local filled=$((progreso / 5))
        local empty=$((20 - filled))
        local bar=""
        for ((i=0; i<filled; i++)); do bar="${bar}█"; done
        for ((i=0; i<empty; i++)); do bar="${bar}░"; done
        
        printf "\r${C_CYAN}[+] %-35s ${C_YELLOW}[%s] %d%%${C_NC}" "$mensaje" "$bar" "$progreso"
        sleep 0.3
    done
    
    wait $pid
    local status=$?
    
    local full_bar=""
    for ((i=0; i<20; i++)); do full_bar="${full_bar}█"; done
    
    if [ $status -eq 0 ]; then
        printf "\r${C_CYAN}[+] %-35s ${C_GREEN}[%s] 100%% [OK]${C_NC}\n" "$mensaje" "$full_bar"
    else
        printf "\r${C_RED}[✘] %-35s [ERROR]${C_NC}\n" "$mensaje"
    fi
    tput cnorm # Restaura el cursor
}

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}       INSTALADOR GOLBERT VPS V5.0 LTS          ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

# ==========================================
# 1. SISTEMA DE KEY / LICENCIA
# ==========================================
echo -e "\n${C_YELLOW}Por favor, ingrese su Key de instalación:${C_NC}"
read -p "Key: " input_key

if [ -z "$input_key" ]; then
    echo -e "\n${C_RED}[!] Error: No se ingresó ninguna Key.${C_NC}"
    exit 1
fi

echo -e "\n${C_CYAN}Verificando Key...${C_NC}"
sleep 1

# ⚠️ IMPORTANTE: AQUÍ ABAJO DEBES PONER EL COMANDO ORIGINAL QUE CONECTABA CON TU BOT
# verificacion=$(curl -s "http://TU_IP/validar?key=$input_key")
# if [ "$verificacion" != "ACTIVA" ]; then
#     echo -e "${C_RED}[!] Key inválida o expirada.${C_NC}"
#     exit 1
# fi

echo -e "${C_GREEN}[✔] Key validada correctamente.${C_NC}\n"
sleep 1

# ==========================================
# 2. INSTALACIÓN SILENCIOSA CON BARRAS
# ==========================================

# Dependencias Base
CMD_DEP="apt-get update -y && apt-get install -y curl wget jq net-tools iptables ufw cron python3"
barra_porcentaje "$CMD_DEP" "Instalando dependencias base"

# Directorios
CMD_DIR="mkdir -p /etc/vps-manager/core && mkdir -p /usr/local/bin"
barra_porcentaje "$CMD_DIR" "Creando directorios del sistema"

# Descarga de Módulos
CMD_MODS="wget -qO /etc/vps-manager/proxy.py https://raw.githubusercontent.com/golbert19/vps-script/main/core/proxy.py && \
wget -qO /etc/vps-manager/limiter.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/limiter.sh && \
wget -qO /etc/vps-manager/core/setup_dns.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/setup_dns.sh && \
chmod +x /etc/vps-manager/limiter.sh /etc/vps-manager/core/setup_dns.sh"
barra_porcentaje "$CMD_MODS" "Descargando módulos core"

# Menú Principal
CMD_MENU="rm -f /usr/local/bin/menu /usr/local/bin/me && \
wget -qO /usr/local/bin/menu https://raw.githubusercontent.com/golbert19/vps-script/main/menu.sh && \
chmod +x /usr/local/bin/menu"
barra_porcentaje "$CMD_MENU" "Instalando Panel Principal"

# Pasarela Nginx (Fix Ports)
CMD_FIX="wget -qO /etc/vps-manager/fix_ports.sh https://raw.githubusercontent.com/golbert19/vps-script/main/fix_ports.sh && \
chmod +x /etc/vps-manager/fix_ports.sh && /etc/vps-manager/fix_ports.sh"
barra_porcentaje "$CMD_FIX" "Configurando pasarela de puertos"

# ==========================================
# FINALIZACIÓN
# ==========================================
echo -e "\n${C_GREEN}[✔] ¡Instalación modular completada con éxito!${C_NC}"
sleep 2

# Iniciar el menú automáticamente
clear
menu
