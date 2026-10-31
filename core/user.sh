# ==========================================
# Función: Crear Nuevo Usuario con Reporte Detallado
# ==========================================
crear_usuario() {
    clear
    echo -e "${C_ORANGE}======================================================${C_NC}"
    echo -e "               ${C_BLUE}[ CREACIÓN DE USUARIO ]${C_NC}"
    echo -e "${C_ORANGE}======================================================${C_NC}"
    read -p " Nombre de usuario: " username
    
    # Verificar si existe
    if id "$username" &>/dev/null; then
        echo -e "\n ${C_RED}[!] Error: El usuario '$username' ya existe.${C_NC}"
        sleep 2
        return
    fi
    
    read -p " Contraseña: " password
    read -p " Días de duración: " dias
    read -p " Límite de conexiones: " limite

    # Creación en el sistema Linux
    useradd -M -s /bin/false -e $(date -d "+$dias days" +%Y-%m-%d) "$username"
    echo "$username:$password" | chpasswd
    
    # Guardar límite de conexiones (Ajusta la ruta si usas CheckUser en otra carpeta)
    mkdir -p /root/usuarios
    echo "$limite" > /root/usuarios/$username.limit

    # Obtener IP Pública
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
    echo -e "${C_ORANGE}          🚀 MÉTODOS DE CONEXIÓN ACTIVOS 🚀${C_NC}"
    echo -e "${C_CYAN}======================================================${C_NC}"

    echo -e " 🔹 SSH Directo : 22"

    # Verificación dinámica de BHTTP (Lee el puerto directamente del script Python)
    if systemctl is-active --quiet bhttp; then
        PORT_BHTTP=$(grep -oP '(?<="port": )[0-9]+' /etc/vps-manager/bhttp/BHTTP.py 2>/dev/null | head -1)
        echo -e " 🔹 BHTTP Proxy : ${PORT_BHTTP:-8180}"
    fi

    # Verificación dinámica de HCR (Lee el puerto desde systemd)
    if systemctl is-active --quiet hcr; then
        PORT_HCR=$(systemctl show hcr.service -p ExecStart 2>/dev/null | grep -oP '(?<=--listen :)[0-9]+' | head -1)
        echo -e " 🔹 HCR Plain   : ${PORT_HCR:-8880}"
    fi

    # Verificación de UDP Custom
    if systemctl is-active --quiet udp-custom; then
        echo -e " 🔹 UDP Custom  : Activo (Puertos 1-65535)"
    fi

    # Verificación de SSL / Stunnel
    if systemctl is-active --quiet stunnel4; then
        echo -e " 🔹 SSL / TLS   : 443, 444"
    fi

    # Verificación de OpenVPN
    if systemctl is-active --quiet openvpn@server || systemctl is-active --quiet openvpn; then
        echo -e " 🔹 OpenVPN     : Activo (Solicita tu perfil .ovpn)"
    fi

    # Verificación de SlowDNS
    if pgrep -x "dns-server" > /dev/null || systemctl is-active --quiet slowdns; then
        echo -e " 🔹 SlowDNS     : Activo"
    fi
    
    # Verificación de Hysteria
    if systemctl is-active --quiet hysteria; then
        echo -e " 🔹 Hysteria    : Activo (UDP)"
    fi

    echo -e "${C_CYAN}======================================================${C_NC}"
    read -p " Presiona Enter para continuar..."
}
