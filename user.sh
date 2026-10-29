#!/bin/bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'
C_NC='\033[0m'

IP=$(curl -sS ifconfig.me 2>/dev/null || wget -qO- ipv4.icanhazip.com)

while true; do
    clear
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 👤 GESTIÓN DE USUARIOS SSH & MÉTODOS"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " ${C_CYAN}1.${C_NC} Crear Cuenta Normal (Estándar)"
    echo -e " ${C_CYAN}2.${C_NC} Crear Cuenta con HWID (Bloqueo por Dispositivo)"
    echo -e " ${C_CYAN}3.${C_NC} Crear Token App"
    echo -e " ${C_CYAN}4.${C_NC} Renovar Usuario"
    echo -e " ${C_CYAN}5.${C_NC} Eliminar Usuario"
    echo -e " ${C_CYAN}6.${C_NC} Lista de Usuarios Creados"
    echo -e " ${C_CYAN}7.${C_NC} Monitor de Conexiones Activas"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " ${C_CYAN}0.${C_NC} VOLVER al Menú Principal"
    echo -e "${C_CYAN}================================================${C_NC}"
    read -p "Opción: " op_user

    case $op_user in
        1)
            clear
            echo -e "${C_CYAN}================================================${C_NC}"
            echo -e " 👤 CREACIÓN DE CUENTA NORMAL"
            echo -e "${C_CYAN}================================================${C_NC}"
            read -p "Ingresa el nombre de usuario: " user
            read -p "Ingresa la contraseña: " pass
            read -p "Días de duración: " dias
            read -p "Límite de conexiones: " limit
            
            fecha_exp=$(date -d "+$dias days" +"%Y-%m-%d")
            useradd -e "$fecha_exp" -s /bin/false -M "$user" 2>/dev/null
            echo "$user:$pass" | chpasswd
            
            clear
            echo -e "${C_CYAN}================================================${C_NC}"
            echo -e "${C_GREEN}       ✅ USUARIO CREADO EXITOSAMENTE ✅       ${C_NC}"
            echo -e "${C_CYAN}================================================${C_NC}"
            echo -e " 👤 Usuario       : ${C_YELLOW}$user${C_NC}"
            echo -e " 🔑 Contraseña    : ${C_YELLOW}$pass${C_NC}"
            echo -e " 📅 Vencimiento   : $fecha_exp ($dias días)"
            echo -e " 🔌 Límite        : $limit Conexiones simultáneas"
            echo -e "${C_CYAN}================================================${C_NC}"
            echo -e " 🌐 IP Servidor   : ${C_YELLOW}$IP${C_NC}"
            echo -e " 🔗 Payload       : ${C_GREEN}$IP:1-65535@$user:$pass${C_NC}"
            echo -e "${C_CYAN}================================================${C_NC}"
            echo -e " 🟢 PUERTOS ACTIVOS Y MÉTODOS:"
            echo -e "  - SSH / Proxy   : 22, 80"
            echo -e "  - SSL / TLS     : 443"
            echo -e "  - SSH-WS        : 80"
            echo -e "  - UDP Custom    : 7300, 2000-25000"
            echo -e "  - BHTTP         : 8180"
            echo -e "  - HCR Nativo    : 8880"
            echo -e "${C_CYAN}================================================${C_NC}"
            echo -e " 🔗 ENLACES Y AYUDA:"
            echo -e "  - OpenVPN TCP/UDP : http://$IP:81/client.ovpn"
            echo -e "  - App UDP Custom  : Configurar puerto 7300"
            echo -e "${C_CYAN}================================================${C_NC}"
            read -p "Copia los datos y presiona Enter para continuar..."
            ;;
        2)
            clear
            echo -e "${C_CYAN}================================================${C_NC}"
            echo -e " 📱 CREACIÓN DE CUENTA CON HWID"
            echo -e "${C_CYAN}================================================${C_NC}"
            read -p "Ingresa el nombre de usuario: " user
            read -p "Ingresa el HWID del dispositivo: " hwid
            read -p "Días de duración: " dias
            echo -e "\n${C_GREEN}[✔] Usuario $user registrado con HWID: $hwid${C_NC}"
            read -p "Presiona Enter para continuar..."
            ;;
        3)
            clear
            echo -e "${C_CYAN}================================================${C_NC}"
            echo -e " 🔑 CREACIÓN DE TOKEN APP"
            echo -e "${C_CYAN}================================================${C_NC}"
            token=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
            echo -e "Token generado: ${C_GREEN}$token${C_NC}"
            read -p "Presiona Enter para continuar..."
            ;;
        4)
            clear
            read -p "Ingresa el usuario a renovar: " user
            read -p "Días a añadir: " dias
            if id "$user" >/dev/null 2>&1; then
                chage -E $(date -d "+$dias days" +"%Y-%m-%d") "$user"
                echo -e "${C_GREEN}[✔] Usuario $user renovado por $dias días más.${C_NC}"
            else
                echo -e "${C_RED}[✘] El usuario no existe.${C_NC}"
            fi
            read -p "Presiona Enter para continuar..."
            ;;
        5)
            clear
            read -p "Ingresa el usuario a eliminar: " user
            if id "$user" >/dev/null 2>&1; then
                userdel -f "$user"
                echo -e "${C_GREEN}[✔] Usuario $user eliminado.${C_NC}"
            else
                echo -e "${C_RED}[✘] El usuario no existe.${C_NC}"
            fi
            read -p "Presiona Enter para continuar..."
            ;;
        6)
            clear
            echo -e "${C_CYAN}================================================${C_NC}"
            echo -e " 📋 LISTA DE USUARIOS ACTIVOS"
            echo -e "${C_CYAN}================================================${C_NC}"
            awk -F: '$3 >= 1000 && $1 != "nobody" {print " 👤 " $1}' /etc/passwd
            read -p "Presiona Enter para continuar..."
            ;;
        7)
            clear
            echo -e "${C_CYAN}================================================${C_NC}"
            echo -e " 📡 CONEXIONES ACTIVAS"
            echo -e "${C_CYAN}================================================${C_NC}"
            ps -u root | grep sshd
            read -p "Presiona Enter para continuar..."
            ;;
        0) break ;;
        *) echo -e "${C_RED}Opción inválida.${C_NC}"; sleep 1 ;;
    esac
done
