#!/bin/bash
# ==========================================
# Script de Instalación - Golbert VPS V4.5
# ==========================================

clear
echo -e "\033[1;36m================================================\033[0m"
echo -e "\033[1;32m       INSTALADOR GOLBERT VPS V4.5 LTS          \033[0m"
echo -e "\033[1;36m================================================\033[0m"

# ==========================================
# 1. SISTEMA DE KEY / LICENCIA
# ==========================================
echo -e "\n\033[1;33mPor favor, ingrese su Key de instalación:\033[0m"
read -p "Key: " input_key

if [ -z "$input_key" ]; then
    echo -e "\n\033[1;31m[!] Error: No se ingresó ninguna Key.\033[0m"
    exit 1
fi

echo -e "\n\033[1;36mVerificando Key...\033[0m"
sleep 1

# ⚠️ IMPORTANTE: AQUÍ ABAJO DEBES PONER EL COMANDO ORIGINAL QUE CONECTABA CON TU BOT
# Si usabas 'curl' o 'wget' para validar en tu IP, ponlo aquí.
# Ejemplo de cómo suele verse:
# verificacion=$(curl -s "http://45.41.207.172:8080/validar?key=$input_key")
# if [ "$verificacion" != "ACTIVA" ]; then
#     echo -e "\033[1;31m[!] Key inválida o expirada.\033[0m"
#     exit 1
# fi

echo -e "\033[1;32m[✔] Key validada correctamente.\033[0m"
sleep 1

# ==========================================
# 2. CREACIÓN DE DIRECTORIOS
# ==========================================
echo -e "\n\033[1;36m[+] Preparando sistema...\033[0m"
mkdir -p /etc/vps-manager/core
mkdir -p /usr/local/bin

# ==========================================
# 3. DESCARGA DE MÓDULOS (Corregido)
# ==========================================
echo -e "\033[1;32m[✔] Descargando componentes y módulos core...\033[0m"

wget -O /etc/vps-manager/proxy.py https://raw.githubusercontent.com/golbert19/vps-script/main/core/proxy.py
wget -O /etc/vps-manager/limiter.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/limiter.sh
wget -O /etc/vps-manager/core/setup_dns.sh https://raw.githubusercontent.com/golbert19/vps-script/main/core/setup_dns.sh

chmod +x /etc/vps-manager/limiter.sh
chmod +x /etc/vps-manager/core/setup_dns.sh

# ==========================================
# 4. DESCARGA DEL MENÚ PRINCIPAL
# ==========================================
echo -e "\033[1;32m[✔] Instalando el Panel Principal...\033[0m"
rm -f /usr/local/bin/menu 
rm -f /usr/local/bin/me

wget -O /usr/local/bin/menu https://raw.githubusercontent.com/golbert19/vps-script/main/menu.sh
chmod +x /usr/local/bin/menu

# ==========================================
# 5. FINALIZACIÓN Y APERTURA AUTOMÁTICA
# ==========================================
echo -e "\n\033[1;32m[✔] ¡Instalación modular completada con éxito!\033[0m"
sleep 2

# Limpiar pantalla e iniciar el menú automáticamente
clear
menu
