#!/bin/bash
# ==========================================
# SCRIPT DE ACTUALIZACIÓN AUTOMÁTICA - GOLBERT VPS
# ==========================================

C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🔄 ${C_YELLOW}ACTUALIZANDO GOLBERT VPS V5.0 LTS${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

# 1. Definir directorios de trabajo
INSTALL_DIR="/etc/vps-manager"
CORE_DIR="$INSTALL_DIR/core"
ROOT_CORE="/root/core"

echo -e "${C_YELLOW}[+] Verificando directorios y permisos...${C_NC}"
mkdir -p "$CORE_DIR" "$ROOT_CORE"

# 2. Descargar o actualizar los archivos desde tu repositorio de GitHub
# (Reemplaza la URL de GitHub por la de tu repositorio oficial)
REPO_URL="https://raw.githubusercontent.com/golbert19/vps-script/main"

echo -e "${C_YELLOW}[+] Descargando componentes actualizados...${C_NC}"

# Lista de scripts principales a actualizar
SCRIPTS=("menu.sh" "sshws.sh" "xray_manager.sh" "user.sh")

for script in "${SCRIPTS[@]}"; do
    wget -q -O "$CORE_DIR/$script" "$REPO_URL/$script" 2>/dev/null
    if [ $? -eq 0 ]; then
        cp -f "$CORE_DIR/$script" "$ROOT_CORE/$script" 2>/dev/null
        chmod +x "$CORE_DIR/$script" "$ROOT_CORE/$script" 2>/dev/null
        echo -e "    • Actualizado: $script"
    else
        echo -e "    • ${C_RED}Error al actualizar $script (verifique la URL)${C_NC}"
    fi
done

# 3. Crear accesos directos globales en el sistema para evitar comandos caídos
if [ -f "$CORE_DIR/menu.sh" ]; then
    ln -sf "$CORE_DIR/menu.sh" /usr/bin/menu
    ln -sf "$CORE_DIR/menu.sh" /usr/bin/vps
    chmod +x /usr/bin/menu /usr/bin/vps
fi

echo -e "${C_CYAN}================================================${C_NC}"
echo -e " ✅ ${C_GREEN}¡ACTUALIZACIÓN COMPLETADA CON ÉXITO!${C_NC}"
echo -e " Escribe ${C_YELLOW}menu${C_NC} o ${C_YELLOW}vps${C_NC} para abrir el panel principal."
echo -e "${C_CYAN}================================================${C_NC}"
sleep 2
