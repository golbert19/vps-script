#!/bin/bash
# ==========================================
# GESTIÓN DE USUARIOS SSH / VPN
# ==========================================

C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_BLUE='\033[1;34m'
C_CYAN='\033[1;36m'
C_ORANGE='\033[38;5;214m'
C_NC='\033[0m'

# 1. Crear Usuario
crear_usuario() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "               ${C_BLUE}[ CREACIÓN DE USUARIO ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Nombre de usuario: " username
    
    if id "$username" &>/dev/null; then
        echo -e "\n ${C_RED}[!] Error: El usuario '$username' ya existe.${C_NC}"
        sleep 2
        return
    fi
    
    read -p " Contraseña: " password
    read -p " Días de duración: " dias
    read -p " Límite de conexiones: " limite

    useradd -M -s /bin/false -e $(date -d "+$dias days" +%Y-%m-%d) "$username"
    echo "$username:$password" | chpasswd
    
    mkdir -p /root/usuarios
    echo "$limite" > /root/usuarios/$username.limit

    IP=$(curl -sS ifconfig.me 2>/dev/null || wget -qO- ipv4.icanhazip.com)

    clear
    echo -e "${C_GREEN}✅ Usuario creado con éxito. Copia los datos abajo:${C_NC}"
    echo -e "${C_CYAN}======================================================${C_NC}"
    echo -e " 👤 Usuario   : $username"
    echo -e " 🔑 Pass      : $password"
    echo -e " ⏳ Vence     : $(date -d "+$dias days" +%d/%m/%Y)"
    echo -e " ⚙️ Límite    : $limite conexión(es)"
    echo -e " 🌐 IP Server : $IP"
    echo -e "${C_CYAN}======================================================${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# 2. Eliminar Usuario
eliminar_usuario() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "               ${C_RED}[ ELIMINAR USUARIO ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Nombre del usuario a eliminar: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "\n ${C_RED}[!] Error: El usuario '$username' no existe.${C_NC}"
        sleep 2
        return
    fi

    userdel --force "$username" 2>/dev/null
    rm -f /root/usuarios/$username.limit
    
    echo -e "\n ${C_GREEN}✅ Usuario '$username' eliminado correctamente.${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# 3. Renovar Usuario
renovar_usuario() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "               ${C_GREEN}[ RENOVAR USUARIO ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Nombre de usuario: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "\n ${C_RED}[!] Error: El usuario '$username' no existe.${C_NC}"
        sleep 2
        return
    fi

    read -p " Días a extender desde hoy: " dias
    chage -E $(date -d "+$dias days" +%Y-%m-%d) "$username"
    
    echo -e "\n ${C_GREEN}✅ Usuario renovado. Nueva fecha de vencimiento: $(date -d "+$dias days" +%d/%m/%Y)${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# 4. Cambiar Contraseña
cambiar_contrasena() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "             ${C_CYAN}[ CAMBIAR CONTRASEÑA ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Nombre de usuario: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "\n ${C_RED}[!] Error: El usuario '$username' no existe.${C_NC}"
        sleep 2
        return
    fi

    read -p " Nueva contraseña: " password
    echo "$username:$password" | chpasswd
    
    echo -e "\n ${C_GREEN}✅ Contraseña actualizada correctamente.${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# 5. Límite de Conexiones
limite_conexiones() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "          ${C_BLUE}[ ESTABLECER LÍMITE DE CONEXIONES ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Nombre de usuario: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "\n ${C_RED}[!] Error: El usuario '$username' no existe.${C_NC}"
        sleep 2
        return
    fi

    read -p " Nuevo límite de conexiones: " limite
    mkdir -p /root/usuarios
    echo "$limite" > /root/usuarios/$username.limit
    
    echo -e "\n ${C_GREEN}✅ Límite actualizado a $limite conexión(es).${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# 6. Detalles de Usuario
detalles_usuario() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "               ${C_CYAN}[ DETALLES DE USUARIO ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Nombre de usuario: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "\n ${C_RED}[!] Error: El usuario '$username' no existe.${C_NC}"
        sleep 2
        return
    fi

    exp_date=$(chage -l "$username" | grep "Account expires" | cut -d: -f2 | sed 's/^ *//')
    status=$(passwd -S "$username" | awk '{print $2}')
    limit="Sin límite"
    [ -f "/root/usuarios/$username.limit" ] && limit=$(cat "/root/usuarios/$username.limit")

    [ "$status" = "L" ] && st="${C_RED}Bloqueado${C_NC}" || st="${C_GREEN}Activo${C_NC}"

    echo -e "\n 👤 Usuario   : $username"
    echo -e " 📅 Vencimiento: $exp_date"
    echo -e " ⚙️ Límite    : $limit"
    echo -e " 🛡️ Estado    : $st"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# 7. Bloquear / Desbloquear Cuenta
bloquear_usuario() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "          ${C_RED}[ BLOQUEAR / DESBLOQUEAR CUENTA ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Nombre de usuario: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "\n ${C_RED}[!] Error: El usuario '$username' no existe.${C_NC}"
        sleep 2
        return
    fi

    echo -e "\n 1. 🔒 Bloquear cuenta"
    echo -e " 2. 🔓 Desbloquear cuenta"
    read -p " Opción: " block_op

    if [ "$block_op" = "1" ]; then
        usermod -L "$username"
        echo -e "\n ${C_GREEN}✅ Usuario '$username' bloqueado.${C_NC}"
    elif [ "$block_op" = "2" ]; then
        usermod -U "$username"
        echo -e "\n ${C_GREEN}✅ Usuario '$username' desbloqueado.${C_NC}"
    else
        echo -e "\n ${C_RED}Opción inválida.${C_NC}"
    fi
    read -p " Presiona Enter para continuar..."
}

# 8. Lista de Usuarios
lista_usuarios() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "          ${C_CYAN}[ LISTA DE USUARIOS Y VENCIMIENTOS ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    printf " %-15s | %-20s | %-10s\n" "USUARIO" "VENCIMIENTO" "ESTADO"
    echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
    
    for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
        exp=$(chage -l "$user" | grep "Account expires" | cut -d: -f2 | sed 's/^ *//')
        status=$(passwd -S "$user" | awk '{print $2}')
        [ "$status" = "L" ] && st="${C_RED}Bloqueado${C_NC}" || st="${C_GREEN}Activo${C_NC}"
        
        # Limpiar fecha para visualización si está en "never"
        [ "$exp" = "never" ] && exp="Nunca"
        
        printf " %-15s | %-20s | %-10s\n" "$user" "$exp" "$st"
    done
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# 9. Usuarios Online
usuarios_online() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "           ${C_GREEN}[ USUARIOS CONECTADOS EN LÍNEA ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    printf " %-15s | %-10s | %-15s\n" "USUARIO" "PID" "PROTOCOLO"
    echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
    
    ps -ef | grep -E 'sshd|dropbear' | grep -v root | grep -v grep | awk '{print $1, $2, $8}' | while read user pid proc; do
        if id "$user" &>/dev/null; then
            protocolo="SSH"
            [[ "$proc" == *"dropbear"* ]] && protocolo="Dropbear"
            printf " %-15s | %-10s | %-15s\n" "$user" "$pid" "$protocolo"
        fi
    done
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Presiona Enter para continuar..."
}

# ==========================================
# Menú Interactivo de Usuarios
# ==========================================
while true; do
    clear
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 👤 GESTIÓN DE CUENTAS SSH / VPN"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 1. ➕ Crear nuevo usuario"
    echo -e " 2. ❌ Eliminar usuario"
    echo -e " 3. 🔄 Renovar usuario (Extender días)"
    echo -e " 4. 🔑 Cambiar contraseña"
    echo -e " 5. ⚙️ Establecer límite de conexiones"
    echo -e " 6. 📋 Detalles de un usuario"
    echo -e " 7. 🔓 Bloquear / Desbloquear cuenta"
    echo -e " 8. 👥 Lista de usuarios y vencimientos"
    echo -e " 9. 📡 Ver usuarios conectados en línea"
    echo -e " 0. 🚪 VOLVER al Menú Principal"
    echo -e "${C_CYAN}================================================${C_NC}"
    read -p " Selecciona una opción: " user_op
    
    case $user_op in
        1) crear_usuario ;;
        2) eliminar_usuario ;;
        3) renovar_usuario ;;
        4) cambiar_contrasena ;;
        5) limite_conexiones ;;
        6) detalles_usuario ;;
        7) bloquear_usuario ;;
        8) lista_usuarios ;;
        9) usuarios_online ;;
        0) break ;;
        *) echo -e "${C_RED}Opción inválida.${C_NC}"; sleep 1 ;;
    esac
done
