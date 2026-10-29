#!/bin/bash
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "        CREAR USUARIO SSH / HWID PROTECTION     "
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " [1] Cuenta Normal"
echo -e " [2] Cuenta HWID"
echo -e " [3] Cuenta por Token (App)"
echo -e " [0] Regresar al Menú Principal"
echo -e "${C_CYAN}================================================${C_NC}"
read -p " Opción: " opt_user

case $opt_user in
    1)
        read -p " Usuario: " username
        read -p " Contraseña: " password
        useradd -M -s /bin/false $username
        (echo "$password"; echo "$password") | passwd $username >/dev/null 2>&1
        echo -e "${C_GREEN}Usuario $username creado con éxito.${C_NC}"
        sleep 2
        ;;
    2)
        # Aquí va la lógica HWID
        ;;
    3)
        # Aquí va la lógica de Tokens Hysteria
        ;;
    0)
        # Sale del script user.sh y el bucle de menu.sh vuelve a cargar
        exit 0 
        ;;
    *)
        echo "Opción inválida."
        sleep 2
        ;;
esac
