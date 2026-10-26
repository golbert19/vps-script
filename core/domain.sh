#!/bin/bash
# ==========================================
# Módulo: Gestor de Dominio y Certificado SSL
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}       GESTOR DE DOMINIO Y CERTIFICADO SSL      ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

read -p "Ingresa tu Subdominio (Ej: vps.dominio.com): " DOMINIO
if [ -z "$DOMINIO" ]; then 
    echo -e "${C_RED}[!] Error: No ingresaste un dominio válido.${C_NC}"
    sleep 2
    exit 1
fi

# Guardar dominio en el sistema
mkdir -p /etc/vps-manager
echo "$DOMINIO" > /etc/vps-manager/dominio

echo -e "${C_YELLOW}[+] Actualizando paquetes e instalando Certbot...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y certbot psmisc >/dev/null 2>&1

echo -e "${C_YELLOW}[+] Deteniendo servicios para liberar el puerto 80...${C_NC}"
systemctl stop nginx apache2 haproxy xray ws-python stunnel4 2>/dev/null
fuser -k 80/tcp 2>/dev/null

echo -e "${C_YELLOW}[+] Generando Certificado SSL Oficial (Let's Encrypt)...${C_NC}"
certbot certonly --standalone -d "$DOMINIO" --non-interactive --agree-tos -m "admin@$DOMINIO"

if [ -d "/etc/letsencrypt/live/$DOMINIO" ]; then
    echo -e "${C_YELLOW}[+] Certificado exitoso. Distribuyendo llaves...${C_NC}"
    mkdir -p /usr/local/etc/xray /etc/stunnel
    
    # Copiar para Xray
    cp /etc/letsencrypt/live/$DOMINIO/fullchain.pem /usr/local/etc/xray/server.crt 2>/dev/null
    cp /etc/letsencrypt/live/$DOMINIO/privkey.pem /usr/local/etc/xray/server.key 2>/dev/null
    chown nobody:nogroup /usr/local/etc/xray/server.crt /usr/local/etc/xray/server.key 2>/dev/null
    
    # Copiar para Stunnel (SSHWS / SSL)
    cat /etc/letsencrypt/live/$DOMINIO/fullchain.pem /etc/letsencrypt/live/$DOMINIO/privkey.pem > /etc/stunnel/stunnel.pem 2>/dev/null
    
    echo -e "${C_GREEN}[✔] ¡Certificado SSL instalado y configurado correctamente!${C_NC}"
else
    echo -e "${C_RED}[!] Error: No se pudo verificar el dominio.${C_NC}"
    echo -e "${C_YELLOW}Por favor, revisa que la IP del VPS esté correctamente vinculada al dominio en Cloudflare y que la nube (proxy) esté desactivada temporalmente (Nube gris).${C_NC}"
fi

echo -e "${C_YELLOW}[+] Reiniciando servicios de red...${C_NC}"
systemctl start xray ws-python stunnel4 2>/dev/null

echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presione Enter para regresar al menú..."
