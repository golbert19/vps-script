#!/bin/bash
# ==========================================
# Módulo: Bot de Telegram (Aislado VENV - Ubuntu 24.04)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

BOT_DIR="/etc/vps-manager/telegram_bot"
mkdir -p "$BOT_DIR"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}         CONFIGURACIÓN DE BOT DE TELEGRAM       ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

if [ -f "$BOT_DIR/config.env" ]; then
    echo -e "${C_YELLOW}[!] Ya hay un bot configurado actualmente.${C_NC}"
    read -p "¿Deseas reconfigurarlo con nuevos datos? (s/n): " reconf
    if [ "$reconf" == "s" ] || [ "$reconf" == "S" ]; then
        rm -f "$BOT_DIR/config.env"
    else
        echo -e "${C_GREEN}Re-iniciando el bot actual...${C_NC}"
        systemctl restart vps-bot
        sleep 2
        exit 0
    fi
fi

echo -e "\n1. Crea un bot en Telegram con ${C_YELLOW}@BotFather${C_NC} y copia su Token."
echo -e "2. Obtén tu ID de Telegram con ${C_YELLOW}@userinfobot${C_NC}\n"

read -p "Ingresa el Token del Bot: " TELEGRAM_TOKEN
read -p "Ingresa tu Admin ID de Telegram: " ADMIN_ID

# Limpiar espacios en blanco por seguridad
TELEGRAM_TOKEN=$(echo "$TELEGRAM_TOKEN" | tr -d ' ' | tr -d '"')
ADMIN_ID=$(echo "$ADMIN_ID" | tr -d ' ' | tr -d '"')

echo "TOKEN=\"$TELEGRAM_TOKEN\"" > "$BOT_DIR/config.env"
echo "ADMIN=\"$ADMIN_ID\"" >> "$BOT_DIR/config.env"

echo -e "\n${C_YELLOW}[+] Instalando Entorno Virtual Python (Para Ubuntu 24.04)...${C_NC}"
apt update -y && apt install -y python3 python3-venv python3-pip jq >/dev/null 2>&1

cd "$BOT_DIR"
# Eliminar entorno viejo si existe y crear uno limpio
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install pyTelegramBotAPI >/dev/null 2>&1

# Crear el script principal de Python
cat << 'EOF' > "$BOT_DIR/bot.py"
import os
import subprocess
import telebot
from telebot import types
import time

# Cargar configuraciones
TOKEN = ""
ADMIN_ID = ""
with open("/etc/vps-manager/telegram_bot/config.env", "r") as f:
    for line in f:
        if line.startswith("TOKEN="):
            TOKEN = line.split("=")[1].strip().strip('"')
        elif line.startswith("ADMIN="):
            ADMIN_ID = line.split("=")[1].strip().strip('"')

bot = telebot.TeleBot(TOKEN)

def is_admin(user_id):
    return str(user_id) == str(ADMIN_ID)

@bot.message_handler(commands=['start', 'help'])
def send_welcome(message):
    if not is_admin(message.from_user.id):
        bot.reply_to(message, "⚠️ <b>No tienes autorización para usar este bot.</b>", parse_mode="HTML")
        return
    
    markup = types.ReplyKeyboardMarkup(row_width=2, resize_keyboard=True)
    markup.add(types.KeyboardButton("👤 Crear SSH"), types.KeyboardButton("❌ Eliminar SSH"))
    markup.add(types.KeyboardButton("📋 Lista SSH"), types.KeyboardButton("📊 Info Servidor"))
    
    bot.reply_to(message, "🤖 <b>Panel Bot Golbert VPS Activado</b>\nSelecciona una opción en el menú inferior:", parse_mode="HTML", reply_markup=markup)

@bot.message_handler(func=lambda message: True)
def handle_message(message):
    if not is_admin(message.from_user.id):
        return

    text = message.text
    if text == "📊 Info Servidor":
        ip = subprocess.getoutput("curl -s ipv4.icanhazip.com")
        ram = subprocess.getoutput("free -m | awk 'NR==2{printf \"%s / %s MB\", $3,$2}'")
        conectados = subprocess.getoutput("ps -ef | grep -E 'sshd|dropbear' | grep -v root | grep -v grep | wc -l")
        msg = f"🌐 <b>IP:</b> {ip}\n⚡ <b>RAM:</b> {ram}\n👥 <b>Conectados:</b> {conectados}"
        bot.reply_to(message, msg, parse_mode="HTML")
        
    elif text == "👤 Crear SSH":
        bot.reply_to(message, "Envía el comando con este formato exacto:\n\n<code>/adduser [usuario] [clave] [dias]</code>\n\nEjemplo: <code>/adduser juan 1234 30</code>", parse_mode="HTML")
        
    elif text.startswith("/adduser"):
        try:
            parts = message.text.split()
            user = parts[1]
            pwd = parts[2]
            days = parts[3]
            
            # Crear usuario en Linux
            cmd = f"useradd -e $(date -d '+{days} days' +'%Y-%m-%d') -s /bin/false -M {user} && echo '{user}:{pwd}' | chpasswd"
            subprocess.getoutput(cmd)
            
            # Obtener datos para respuesta
            ip = subprocess.getoutput("curl -s ipv4.icanhazip.com")
            dom = subprocess.getoutput("[ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo '" + ip + "'")
            exp_date = subprocess.getoutput(f"date -d '+{days} days' +'%Y-%m-%d'")
            
            # INYECTAR BANNER DINÁMICO
            banner_cmd = f"cat /etc/issue.net > /etc/vps-manager/banner_{user}.net && echo \"<br><font color='cyan'>=======================</font><br><font color='yellow'>👤 Usuario:</font> <font color='white'>{user}</font><br><font color='yellow'>📅 Expira:</font> <font color='white'>{exp_date} ({days} Días)</font><br><font color='cyan'>=======================</font><br>\" >> /etc/vps-manager/banner_{user}.net && sed -i '/Match User {user}/d' /etc/ssh/sshd_config && sed -i '/Banner \\/etc\\/vps-manager\\/banner_{user}.net/d' /etc/ssh/sshd_config && echo -e '\\nMatch User {user}\\nBanner /etc/vps-manager/banner_{user}.net' >> /etc/ssh/sshd_config && systemctl restart ssh"
            subprocess.getoutput(banner_cmd)

            respuesta = f"✅ <b>CUENTA CREADA</b> ✅\n\n👤 <b>Usuario:</b> {user}\n🔑 <b>Clave:</b> {pwd}\n📅 <b>Expira:</b> {exp_date} ({days} días)\n🌐 <b>Host:</b> {dom}"
            bot.reply_to(message, respuesta, parse_mode="HTML")
        except Exception as e:
            bot.reply_to(message, "❌ <b>Error.</b> Formato correcto:\n<code>/adduser usuario clave dias</code>", parse_mode="HTML")

    elif text == "❌ Eliminar SSH":
        bot.reply_to(message, "Envía el comando así:\n\n<code>/deluser [usuario]</code>", parse_mode="HTML")
        
    elif text.startswith("/deluser"):
        try:
            user = message.text.split()[1]
            subprocess.getoutput(f"userdel -f {user}")
            subprocess.getoutput(f"rm -f /etc/vps-manager/banner_{user}.net")
            subprocess.getoutput(f"sed -i '/Match User {user}/,+1d' /etc/ssh/sshd_config")
            subprocess.getoutput("systemctl restart ssh")
            bot.reply_to(message, f"✅ Usuario <b>{user}</b> eliminado del sistema.", parse_mode="HTML")
        except:
            bot.reply_to(message, "❌ <b>Error.</b> Formato:\n<code>/deluser usuario</code>", parse_mode="HTML")
            
    elif text == "📋 Lista SSH":
        try:
            output = subprocess.getoutput("awk -F: '$3 >= 1000 && $1 != \"nobody\" {print $1}' /etc/passwd")
            users = output.split('\n')
            msg = "📋 <b>USUARIOS ACTIVOS:</b>\n\n"
            for u in users:
                if u.strip():
                    exp = subprocess.getoutput(f"chage -l {u} | grep 'Account expires' | awk -F': ' '{{print $2}}'")
                    if "never" not in exp.lower() and exp.strip() != "":
                        msg += f"👤 <b>{u}</b> - 📅 {exp}\n"
                    else:
                        msg += f"👤 <b>{u}</b> - 📅 Ilimitado\n"
                        
            if msg == "📋 <b>USUARIOS ACTIVOS:</b>\n\n":
                msg = "No hay usuarios creados."
            bot.reply_to(message, msg, parse_mode="HTML")
        except:
            bot.reply_to(message, "❌ Error al obtener lista.")

if __name__ == "__main__":
    while True:
        try:
            bot.infinity_polling(timeout=10, long_polling_timeout=5)
        except Exception as e:
            time.sleep(3)
EOF

# Crear servicio Systemd para mantener el bot online 24/7 y vincularlo al VENV
cat << EOF > /etc/systemd/system/vps-bot.service
[Unit]
Description=Telegram Bot Golbert VPS
After=network.target

[Service]
User=root
WorkingDirectory=$BOT_DIR
ExecStart=$BOT_DIR/venv/bin/python $BOT_DIR/bot.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vps-bot >/dev/null 2>&1
systemctl restart vps-bot

echo -e "\n${C_GREEN}[✔] ¡Bot de Telegram Aislado configurado e iniciado con éxito!${C_NC}"
read -p "Presione Enter para regresar..."
