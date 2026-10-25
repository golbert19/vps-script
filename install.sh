#!/bin/bash
# ==========================================
# Script de Instalación - Golbert VPS V4.5
# ==========================================

clear
echo -e "\033[1;36mIniciando instalación de módulos para Golbert VPS...\033[0m"
sleep 2

# 1. Crear directorios necesarios
mkdir -p /etc/vps-manager/core
mkdir -p /usr/local/bin

# 2. Descargar componentes y módulos core desde GitHub
echo -e "\n\033[1;32m[✔] Descargando componentes y módulos core...\033[0m"

wget -O /etc/vps-manager/proxy.py https://raw.githubusercontent.com/golbert19/vps-script/main/core/proxy.py
wget -O /etc/vps-manager/limiter.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/limiter.sh
wget -O /etc/vps-manager/core/setup_dns.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/setup_dns.sh

# Dar permisos a los módulos
chmod +x /etc/vps-manager/limiter.sh
chmod +x /etc/vps-manager/core/setup_dns.sh

# 3. Descargar el Menú Principal
echo -e "\n\033[1;32m[✔] Descargando e instalando el Menú Principal...\033[0m"
rm -f /usr/local/bin/menu
rm -f /usr/local/bin/me  # Limpieza de errores previos

wget -O /usr/local/bin/menu https://raw.githubusercontent.com/golbert19/vps-script/main/menu.sh
chmod +x /usr/local/bin/menu

# 4. Finalización
echo -e "\n\033[1;32m[✔] ¡Instalación modular completada con éxito!\033[0m"
sleep 2

# 5. Limpiar la terminal e ingresar al panel principal de forma automática
clear
menu
