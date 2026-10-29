#!/bin/bash
# ==========================================
# SCRIPT DE ACTUALIZACIÓN FORZADA (EMERGENCIA)
# Golbert VPS V5.0 LTS
# ==========================================

C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🚀 ${C_YELLOW}FORZANDO ACTUALIZACIÓN DE GOLBERT VPS${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

# 1. Asegurar directorios limpios
echo -e "${C_YELLOW}[+] Reparando estructura de carpetas...${C_NC}"
mkdir -p /etc/vps-manager/core /root/core

# 2. URL base de tu repositorio en GitHub
REPO_URL="https://raw.githubusercontent.com/golbert19/vps-script/main"

# 3. Descargar cada componente crítico directamente
echo -e "${C_YELLOW}[+] Descargando archivos actualizados...${C_NC}"

SCRIPTS_ROOT=("menu.sh" "user.sh")
SCRIPTS_CORE=("sshws.sh" "xray_manager.sh")

# Descargar scripts de la raíz (/main/)
for script in "${SCRIPTS_ROOT[@]}"; do
    rm -f /etc/vps-manager/core/$script /root/core/$script 2>/dev/null
    wget -q -O /etc/vps-manager/core/$script "$REPO_URL/$script"
    if [ $? -eq 0 ]; then
        cp -f /etc/vps-manager/core/$script /root/core/$script
        chmod +x /etc/vps-manager/core/$script /root/core/$script
        echo -e "    • [OK] $script actualizado."
    else
        echo -e "    • ${C_RED}[X] Error al descargar $script${C_NC}"
    fi
done

# Descargar scripts de la subcarpeta (/main/core/)
for script in "${SCRIPTS_CORE[@]}"; do
    rm -f /etc/vps-manager/core/$script /root/core/$script 2>/dev/null
    wget -q -O /etc/vps-manager/core/$script "$REPO_URL/core/$script"
    if [ $? -eq 0 ]; then
        cp -f /etc/vps-manager/core/$script /root/core/$script
        chmod +x /etc/vps-manager/core/$script /root/core/$script
        echo -e "    • [OK] $script actualizado."
    else
        echo -e "    • ${C_RED}[X] Error al descargar $script${C_NC}"
    fi
done

# 4. Reparar accesos directos globales en el sistema
echo -e "${C_YELLOW}[+] Configurando accesos directos del panel...${C_NC}"
if [ -f /etc/vps-manager/core/menu.sh ]; then
    ln -sf /etc/vps-manager/core/menu.sh /usr/bin/menu
    ln -sf /etc/vps-manager/core/menu.sh /usr/bin/vps
    chmod +x /usr/bin/menu /usr/bin/vps
fi

# 5. Limpieza final de caché de comandos
hash -r 2>/dev/null

echo -e "${C_CYAN}================================================${C_NC}"
echo -e " ✅ ${C_GREEN}¡ACTUALIZACIÓN FORZADA EXITOSA!${C_NC}"
echo -e " Ya puedes escribir ${C_YELLOW}menu${C_NC} o ${C_YELLOW}vps${C_NC} para abrir el panel."
echo -e "${C_CYAN}================================================${C_NC}"
