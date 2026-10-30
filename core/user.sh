#!/bin/bash
# ==========================================
# SSH Management - Golbert VPS V5.0 LTS
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

# Crear carpeta para almacenar límites si no existe
mkdir -p /etc/vps-manager/limits

while true; do
    clear
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " 👤 ${C_YELLOW}GESTIÓN DE CUENTAS SSH / VPN${C_NC}"
    echo -e "${C_CYAN}================================================${C_NC}"
    echo -e " ${C_CYAN}1.${C_NC} ➕ Crear nuevo usuario"
    echo -e " ${C_CYAN}2.${C_NC} ❌ Eliminar usuario"
    echo -e " ${C_CYAN}3.${C_NC} 🔄 Renovar usuario (Extender días)"
    echo -e " ${C_CYAN}4.${C_NC} 🔑 Cambiar contraseña"
    echo -e " ${C_CYAN}5.${C_NC} ⚙️ Establecer límite de conexiones"
    echo -e " ${C_CYAN}6.${C_NC} 📋 Detalles de un usuario"
    echo -e " ${C_CYAN}7.${C_NC} 🔒 Bloquear / Desbloquear cuenta"
    echo -e " ${C_CYAN}8.${C_NC} 👥 Lista de usuarios y vencimientos"
    echo -e " ${C_CYAN}0.${C_NC} 🚪 Volver al Menú Principal"
    echo -e "${C_CYAN}================================================${C_NC}"
    read -p " Selecciona una opción: " op_user

    case $op_user in
        1)
            echo -e "\n${C_YELLOW}[ Creación de Usuario ]${C_NC}"
            read -p " Nombre de usuario: " user
            if id "$user" &>/dev/null; then
                echo -e "${C_RED}El usuario '$user' ya existe.${C_NC}"
                sleep 2; continue
            fi
            read -p " Contraseña: " pass
            read -p " Días de duración: " dias
            read -p " Límite de conexiones: " limite
            
            # Crear cuenta sin acceso shell para mayor seguridad
            useradd -M -s /bin/false "$user"
            echo "$user:$pass" | chpasswd
            
            # Aplicar expiración en el sistema
            exp_date=$(date -d "+$dias days" +"%Y-%m-%d")
            chage -E "$exp_date" "$user"
            echo "$limite" > "/etc/vps-manager/limits/$user"
            
            echo -e "\n${C_GREEN}✅ Usuario creado con éxito:${C_NC}"
            echo -e " 👤 Usuario: $user\n 🔑 Pass: $pass\n ⏳ Vence: $exp_date\n ⚙️ Límite: $limite"
            read -p "Presiona Enter para continuar..."
            ;;
        2)
            read -p " Usuario a eliminar: " user
            if id "$user" &>/dev/null; then
                userdel --force "$user"
                rm -f "/etc/vps-manager/limits/$user"
                echo -e "${C_GREEN}✅ Usuario '$user' eliminado completamente.${C_NC}"
            else
                echo -e "${C_RED}Usuario no encontrado.${C_NC}"
            fi
            sleep 2
            ;;
        3)
            read -p " Usuario a renovar: " user
            if id "$user" &>/dev/null; then
                read -p " Días a sumar desde hoy: " dias
                new_date=$(date -d "+$dias days" +"%Y-%m-%d")
                chage -E "$new_date" "$user"
                echo -e "${C_GREEN}✅ Usuario '$user' renovado hasta: $new_date.${C_NC}"
            else
                echo -e "${C_RED}Usuario no encontrado.${C_NC}"
            fi
            sleep 2
            ;;
        4)
            read -p " Usuario: " user
            if id "$user" &>/dev/null; then
                read -p " Nueva contraseña: " pass
                echo "$user:$pass" | chpasswd
                echo -e "${C_GREEN}✅ Contraseña actualizada.${C_NC}"
            else
                echo -e "${C_RED}Usuario no encontrado.${C_NC}"
            fi
            sleep 2
            ;;
        5)
            read -p " Usuario: " user
            if id "$user" &>/dev/null; then
                read -p " Nuevo límite de conexiones: " limite
                echo "$limite" > "/etc/vps-manager/limits/$user"
                echo -e "${C_GREEN}✅ Límite actualizado a $limite conexiones.${C_NC}"
            else
                echo -e "${C_RED}Usuario no encontrado.${C_NC}"
            fi
            sleep 2
            ;;
        6)
            read -p " Usuario: " user
            if id "$user" &>/dev/null; then
                exp=$(chage -l "$user" | grep "Account expires" | awk -F': ' '{print $2}')
                limite=$(cat "/etc/vps-manager/limits/$user" 2>/dev/null || echo "No definido")
                echo -e "\n${C_YELLOW}Detalles de $user:${C_NC}"
                echo -e " Expira: $exp"
                echo -e " Límite: $limite conexiones"
            else
                echo -e "${C_RED}Usuario no encontrado.${C_NC}"
            fi
            read -p "Presiona Enter para continuar..."
            ;;
        7)
            read -p " Usuario a bloquear/desbloquear: " user
            if id "$user" &>/dev/null; then
                status=$(passwd -S "$user" | awk '{print $2}')
                if [ "$status" = "L" ]; then
                    passwd -u "$user" >/dev/null 2>&1
                    echo -e "${C_GREEN}✅ Usuario '$user' DESBLOQUEADO.${C_NC}"
                else
                    passwd -l "$user" >/dev/null 2>&1
                    echo -e "${C_RED}🔒 Usuario '$user' BLOQUEADO.${C_NC}"
                fi
            else
                echo -e "${C_RED}Usuario no encontrado.${C_NC}"
            fi
            sleep 2
            ;;
        8)
            echo -e "\n${C_YELLOW}[ LISTA DE USUARIOS SSH ]${C_NC}"
            awk -F':' '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd | while read -r usr; do
                exp=$(chage -l "$usr" | grep -i "account expires" | awk -F': ' '{print $2}')
                echo -e " 👤 $usr -> ⏳ $exp"
            done
            read -p "Presiona Enter para continuar..."
            ;;
        0) break ;;
        *) echo -e "${C_RED}Opción inválida.${C_NC}" ; sleep 1 ;;
    esac
done
