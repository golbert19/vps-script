mkdir -p /etc/vps-manager/core
cat << 'EOF' > /etc/vps-manager/core/update.sh
#!/bin/bash
# ==========================================
# Módulo: Actualizador Completo de Panel
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🔄 ${C_YELLOW}ACTUALIZADOR DE PANEL - GOLBERT VPS${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_YELLOW}[+] Conectando con GitHub para actualizar componentes...${C_NC}"

REPO_URL="https://raw.githubusercontent.com/golbert19/vps-script/main"

# 1. Actualizar menú principal
echo -e "\n${C_CYAN}[1/3] Actualizando Menú Principal...${C_NC}"
wget --progress=bar:force "$REPO_URL/menu.sh" -O /usr/local/bin/menu
chmod +x /usr/local/bin/menu

# 2. Actualizar archivo de idiomas
echo -e "\n${C_CYAN}[2/3] Sincronizando idiomas...${C_NC}"
wget --progress=bar:force "$REPO_URL/languages.sh" -O /etc/vps-manager/languages.sh 2>/dev/null
chmod +x /etc/vps-manager/languages.sh 2>/dev/null

# 3. Actualizar submódulos críticos de la carpeta core
echo -e "\n${C_CYAN}[3/3] Actualizando módulos del sistema (specs, fix_ports, domain)...${C_NC}"
wget --progress=bar:force "$REPO_URL/core/specs.sh" -O /etc/vps-manager/core/specs.sh 2>/dev/null
wget --progress=bar:force "$REPO_URL/core/fix_ports.sh" -O /etc/vps-manager/core/fix_ports.sh 2>/dev/null
wget --progress=bar:force "$REPO_URL/core/domain.sh" -O /etc/vps-manager/core/domain.sh 2>/dev/null
wget --progress=bar:force "$REPO_URL/core/banner.sh" -O /etc/vps-manager/core/banner.sh 2>/dev/null

chmod +x /etc/vps-manager/core/*.sh 2>/dev/null

echo -e "\n${C_GREEN}[✔] ¡Actualización completada exitosamente!${C_NC}"
echo -e "${C_YELLOW}Reiniciando el panel...${C_NC}"
sleep 2
clear
menu
EOF

chmod +x /etc/vps-manager/core/update.sh
