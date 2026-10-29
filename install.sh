#!/bin/bash
# ==========================================
# Instalador Maestro - Golbert VPS V5.0 LTS
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

# Ocultar el cursor durante la instalación para mayor limpieza visual
tput civis

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌟 ${C_YELLOW}INSTALADOR GOLBERT VPS V5.0 LTS${C_NC} 🌟"
echo -e "${C_CYAN}================================================${C_NC}"

# --- 1. Verificación de Sistema Operativo (Ubuntu/Debian) ---
echo -n -e "${C_YELLOW}[+] Verificando compatibilidad del sistema... ${C_NC}"
if grep -Eqi "(ubuntu|debian)" /etc/os-release; then
    os_ver=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
    echo -e "${C_GREEN}[✔] ${os_ver}${C_NC}"
else
    echo -e "\n${C_RED}[✘] Error: Este script está optimizado para Ubuntu o Debian.${C_NC}"
    tput cnorm; exit 1
fi

# --- 2. Instalación de Dependencias Críticas (Silencioso) ---
echo -n -e "${C_YELLOW}[+] Configurando dependencias (Por favor espere)... ${C_NC}"
apt-get update -y > /dev/null 2>&1
apt-get install -y wget curl net-tools bc lsof unzip > /dev/null 2>&1
echo -e "${C_GREEN}[✔] Listo${C_NC}"

# --- 3. Crear Estructura de Carpetas ---
mkdir -p /etc/vps-manager/core

# --- 4. Descarga de Archivos con Barra de Progreso Animada ---
REPO_URL="https://raw.githubusercontent.com/golbert19/vps-script/main"

# Diccionario de archivos a descargar (repo_path : local_path)
FILES=(
    "menu.sh:usr/local/bin/menu"
    "languages.sh:etc/vps-manager/languages.sh"
    "install.sh:etc/vps-manager/install.sh"
    "core/specs.sh:etc/vps-manager/core/specs.sh"
    "core/fix_ports.sh:etc/vps-manager/core/fix_ports.sh"
    "core/domain.sh:etc/vps-manager/core/domain.sh"
    "core/banner.sh:etc/vps-manager/core/banner.sh"
    "core/update.sh:etc/vps-manager/core/update.sh"
    "core/user.sh:etc/vps-manager/core/user.sh"
    "core/bot.sh:etc/vps-manager/core/bot.sh"
    "core/webpanel.sh:etc/vps-manager/core/webpanel.sh"
    "core/firewall.sh:etc/vps-manager/core/firewall.sh"
    "core/checkuser.sh:etc/vps-manager/core/checkuser.sh"
    "core/xray_manager.sh:etc/vps-manager/core/xray_manager.sh"
    "core/vmess.sh:etc/vps-manager/core/vmess.sh"
    "core/vless.sh:etc/vps-manager/core/vless.sh"
    "core/trojan.sh:etc/vps-manager/core/trojan.sh"
    "core/slowdns.sh:etc/vps-manager/core/slowdns.sh"
    "core/badvpn.sh:etc/vps-manager/core/badvpn.sh"
    "core/hcr.sh:etc/vps-manager/core/hcr.sh"
    "core/hysteria.sh:etc/vps-manager/core/hysteria.sh"
    "core/udp_custom.sh:etc/vps-manager/core/udp_custom.sh"
    "core/bhttp.sh:etc/vps-manager/core/bhttp.sh"
    "core/sshws.sh:etc/vps-manager/core/sshws.sh"
    "core/ssl.sh:etc/vps-manager/core/ssl.sh"
    "core/setup_openvpn.sh:etc/vps-manager/core/setup_openvpn.sh"
    "core/zivpn.sh:etc/vps-manager/core/zivpn.sh"
    "core/bbr.sh:etc/vps-manager/core/bbr.sh"
    "core/php.sh:etc/vps-manager/core/php.sh"
    "core/ports.sh:etc/vps-manager/core/ports.sh"
)

TOTAL=${#FILES[@]}
CURRENT=0

echo -e "${C_YELLOW}[+] Descargando e instalando módulos principales:${C_NC}"
echo "" # Espacio reservado para la barra animada

for entry in "${FILES[@]}"; do
    # Extraer rutas
    repo_path="${entry%%:*}"
    local_path="${entry##*:}"
    
    # Descargar y dar permisos silenciosamente
    wget -qO "/$local_path" "$REPO_URL/$repo_path" 2>/dev/null
    chmod +x "/$local_path" 2>/dev/null
    
    # Calcular y dibujar la barra de progreso
    ((CURRENT++))
    PERCENT=$((CURRENT * 100 / TOTAL))
    BAR_LENGTH=35
    FILLED=$((PERCENT * BAR_LENGTH / 100))
    EMPTY=$((BAR_LENGTH - FILLED))
    
    BAR="["
    for ((i=0; i<FILLED; i++)); do BAR="${BAR}█"; done
    for ((i=0; i<EMPTY; i++)); do BAR="${BAR}▒"; done
    BAR="${BAR}]"
    
    # Animación: retrocede una línea, limpia y dibuja de nuevo
    printf "\r\033[1A\033[K${C_CYAN}%s %3d%% ${C_NC}(%s)\n" "$BAR" "$PERCENT" "$repo_path"
    sleep 0.1 # Pequeña pausa para una transición fluida a la vista
done

# Restaurar el cursor al finalizar
tput cnorm

echo -e "\n${C_GREEN}[✔] ¡Instalación y sincronización completadas con éxito!${C_NC}"
echo -e "${C_YELLOW}Escribe ${C_CYAN}menu${C_YELLOW} en tu terminal para abrir el panel principal.${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
