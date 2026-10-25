#!/bin/bash
# ==========================================
# Módulo: Bot de Telegram para Gestión VPS
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

BOT_DIR="/etc/vps-manager/telegram_bot"
mkdir -p "$BOT_DIR"

clear
echo -e "${C_CYAN}================================================${NC}"
echo -e "${C_GREEN}         CONFIGURACIÓN DE BOT DE TELEGRAM       ${NC}"
echo -e "${C_CYAN}================================================${NC}"

if [ -f "$BOT_DIR/config.env" ]; then
    source "$BOT_DIR/config.env"
    echo -e "${C_YELLOW}[!] Ya hay un bot configurado.${NC}"
    read -p "¿Deseas reconfigurarlo? (s/n): " reconf
    [ "$reconf" != "s" ] && exit 0
fi

echo -e "\n1. Crea un bot en Telegram con ${C_YELLOW}@BotFather${C_YELLOW} y copia su Token."
echo -e "2. Obtén tu ID de Telegram con ${C_YELLOW}@userinfobot${C_YELLOW}\n"

read -p "Ingresa el Token del Bot: " TELEGRAM_TOKEN
read -p "Ingresa tu Admin ID de Telegram: " ADMIN_ID

echo "TOKEN=\"$TELEGRAM_TOKEN\"" > "$BOT_DIR/config.env"
echo "ADMIN=\"$ADMIN_ID\"" >> "$BOT_DIR/config.env"

# Crear el script de Python del Bot
cat << 'EOF' > "$BOT_DIR/bot.py"
import os
import subprocess
import telebot
from telebot import types

# Cargar configuración
config_path = "/etc/vps-manager/telegram_bot/config.env"
TOKEN = ""
ADMIN_ID = ""

if os.path.exists(config_path):
    with open(config_path, "r") as f:
        for line in f:
            if line.startswith("TOKEN="):
                TOKEN = line.split("=")[1].strip().strip('"')
            elif line.startswith("ADMIN="):
                ADMIN_ID = line.split("=")[1].strip().strip('"')

bot = telebot.TeleBot(TOKEN)

@bot.message_handler(commands=['start'])
def send_welcome(message):
    if str(message.from_user.id) != str(ADMIN_ID):
        bot.reply_to(message, "⚠️ No tienes autorización para usar este bot.")
        return
    
    markup = types.ReplyKeyboardMarkup(row_width=2, resize_keyboard=True)
    btn_crear = types.KeyboardButton("👤 Crear SSH")
    btn_eliminar = types.KeyboardButton("❌ Eliminar SSH")
    btn_info = types.KeyboardButton("📊 Info Servidor")
    markup.add(btn_crear, btn_eliminar, btn_info)
    
    bot.reply_to(message, "🤖 <b>Panel Bot Golbert VPS Activado</b>\nSelecciona una opción:", parse_mode="HTML", reply_markup=markup)

@bot.message_handler(func=lambda message: True)
def handle_message(message):
    if str(message.from_user.id) != str(ADMIN_ID):
        return

    text = message.text
    if text == "📊 Info Servidor":
        ip = subprocess.getoutput("curl -s ipv4.icanhazip.com")
        ram = subprocess.getoutput("free -m | awk 'NR==2{printf \"%s / %s MB\", $3,$2}'")
        cpu = subprocess.getoutput("top -bn1 | grep load | awk '{printf \"%.2f\", $(NF-2)}'")
        msg = f"🌐 <b>IP:</b> {ip}\n⚡ <b>RAM:</b> {ram}\n💻 <b>CPU Load:</b> {cpu}"
        bot.reply_to(message, msg, parse_mode="HTML")
        
    elif text == "👤 Crear SSH":
        bot.reply_to(message, "Envía los datos en el siguiente formato:\n<code>/adduser [usuario] [contraseña] [días]</code>", parse_mode="HTML")
        
    elif text.startswith("/adduser"):
        try:
            parts = message.text.split()
            user = parts[1]
            pwd = parts[2]
            days = parts[3]
            
            # Comando Linux para crear usuario
            cmd = f"useradd -e $(date -d '+{days} days' +'%Y-%m-%d') -s /bin/false -M {user} && echo '{user}:{pwd}' | chpasswd"
            res = subprocess.getoutput(cmd)
            
            ip = subprocess.getoutput("curl -s ipv4.icanhazip.com")
            dom = subprocess.getoutput("[ -f /etc/vps-manager/dominio ] && cat /etc/vps-manager/dominio || echo '" + ip + "'")
            
            respuesta = f"✅ <b>CUENTA CREADA DESDE TELEGRAM</b> ✅\n\n👤 <b>Usuario:</b> {user}\n🔑 <b>Clave:</b> {pwd}\n📅 <b>Días:</b> {days}\n🌐 <b>Host:</b> {dom}"
            bot.reply_to(message, respuesta, parse_mode="HTML")
        except Exception as e:
            bot.reply_to(message, f"❌ Error al crear usuario. Formato correcto:\n/adduser usuario clave dias")

if __name__ == "__main__":
    print("Bot de Telegram iniciado...")
    bot.infinity_polling()
EOF

# Instalar dependencias de Python para Telegram
apt update -y && apt install -y python3-pip python3-telebot >/dev/null 2>&1
pip install pyTelegramBotAPI --break-system-packages >/dev/null 2>&1

# Crear servicio Systemd para mantener el bot online 24/7
cat << EOF > /etc/systemd/system/vps-bot.service
[Unit]
Description=Telegram Bot Golbert VPS
After=network.target

[Service]
ExecStart=/usr/bin/python3 $BOT_DIR/bot.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vps-bot >/dev/null 2>&1
systemctl restart vps-bot

echo -e "\n${C_GREEN}[✔] ¡Bot de Telegram configurado e iniciado con éxito!${C_NC}"
read -p "Presione Enter para regresar..."
