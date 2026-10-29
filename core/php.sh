mkdir -p /etc/vps-manager/core
cat << 'EOF' > /etc/vps-manager/core/php.sh
#!/bin/bash
C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_NC='\033[0m'
clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🐘 ${C_YELLOW}INSTALADOR DE PHP 8.5.12 - GOLBERT VPS${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_YELLOW}[+] Ejecutando instalador oficial...${C_NC}"
curl -sSL "https://raw.githubusercontent.com/golbert19/php-8.5.12-vps/main/install.sh?t=$(date +%s)" | sed '59s/[()]//g' | bash
echo -e "\n${C_GREEN}[✔] Proceso de PHP finalizado.${C_NC}"
read -p "Presiona Enter para regresar..."
EOF
chmod +x /etc/vps-manager/core/php.sh
