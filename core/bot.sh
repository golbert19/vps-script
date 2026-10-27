#!/bin/bash
# ==========================================
# Módulo: Bot de Telegram (Menú Maestro Original)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

BOT_DIR="/etc/vps-manager/telegram_bot"
mkdir -p "$BOT_DIR"
touch "$BOT_DIR/resellers.txt"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}    CONFIGURACIÓN DE BOT (MENÚ MAESTRO)         ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

if [ -f "$BOT_DIR/config.env" ]; then
    echo -e "${C_YELLOW}[+] Bot ya configurado.${C_NC}"
    read -p "¿Deseas reconfigurar Token y Admin ID? (s/n): " reconf
    if [[ "$reconf" == "s" || "$reconf" == "S" ]]; then
        rm -f "$BOT_DIR/config.env"
    else
        echo -e "${C_GREEN}Actualizando el sistema del bot actual...${C_NC}"
    fi
fi

if [ ! -f "$BOT_DIR/config.env" ]; then
    read -p "Ingresa el Token del Bot: " TELEGRAM_TOKEN
    read -p "Ingresa tu Admin ID de Telegram: " ADMIN_ID
    TELEGRAM_TOKEN=$(echo "$TELEGRAM_TOKEN" | tr -d ' ' | tr -d '"')
    ADMIN_ID=$(echo "$ADMIN_ID" | tr -d ' ' | tr -d '"')
    echo "TOKEN=\"$TELEGRAM_TOKEN\"" > "$BOT_DIR/config.env"
    echo "ADMIN=\"$ADMIN_ID\"" >> "$BOT_DIR/config.env"
fi

apt update -y && apt install -y python3 python3-venv python3-pip jq uuid-runtime net-tools >/dev/null 2>&1

cd "$BOT_DIR"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    source venv/bin/activate
    pip install pyTelegramBotAPI >/dev/null 2>&1
fi

cat << 'EOF' > "$BOT_DIR/bot.py"
import os
import subprocess
import telebot
from telebot import types
import time
import uuid

# Cargar configuración
BOT_DIR = "/etc/vps-manager/telegram_bot"
TOKEN = ""
ADMIN_ID = ""

with open(os.path.join(BOT_DIR, "config.env"), "r") as f:
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
    uid = str(message.from_user.id)
    if is_admin(uid):
        # TECLADO RESTAURADO EXACTAMENTE COMO EN LA IMAGEN
        markup = types.ReplyKeyboardMarkup(row_width=2, resize_keyboard=True)
        markup.add("📊 Estado", "📁 Mis Dominios")
        markup.add("🌐 Dominio A", "🧩 Dominio NS")
        markup.add("🔑 Generar key")
        markup.add("📜 Mi Historial", "📈 Mi Uso")
        markup.add("🆔 Mi ID")
        markup.add("➕ Add User", "🔍 Buscar ID")
        markup.add("📜 Logs Keys", "🏆 Ranking")
        markup.add("👥 Mis Clientes", "🌐 Lista de IPs")
        
        bot.reply_to(message, "👑 <b>Panel ADMIN VPS Activo</b>\nBienvenido a tu menú principal.", parse_mode="HTML", reply_markup=markup)
    else:
        bot.reply_to(message, f"⚠️ <b>Acceso Denegado.</b>\nNo eres el administrador del bot.\nTu ID es: <code>{uid}</code>", parse_mode="HTML")

@bot.message_handler(func=lambda message: True)
def handle_message(message):
    uid = str(message.from_user.id)
    if not is_admin(uid):
        return

    text = message.text
    username = message.from_user.username if message.from_user.username else "Usuario"

    # ==========================
    # FUNCIONES PRINCIPALES
    # ==========================
    if text == "🔑 Generar key":
        try:
            new_key = "VPS-" + str(uuid.uuid4()).upper().replace("-", "")[:12]
            new_key = f"{new_key[:4]}-{new_key[4:8]}-{new_key[8:12]}"

            msg = (
                "✅ <b>KEY GENERADA</b>\n"
                "━━━━━━━━━━━━━━━━━━━━\n"
                f"👤 <b>Cliente:</b> @{username} (ID: <code>{uid}</code>)\n"
                f"🔑 <b>Key:</b> <code>{new_key}</code>\n"
                "⏳ <b>Vence:</b> Permanente (Dueño)\n"
                "━━━━━━━━━━━━━━━━━━━━\n"
                "⚠️ <b>Sistema:</b> Solo Ubuntu 22.04 | 24.04 | 26.04\n"
                "👨‍💻 <b>Dueño:</b> @golbertperuvps\n"
                "━━━━━━━━━━━━━━━━━━━━\n"
                "💻 <b>Instalación:</b>\n"
                "<code>apt update -y && apt install -y wget && wget -O install.sh https://raw.githubusercontent.com/golbert19/vps-script/main/install.sh && chmod +x install.sh && ./install.sh</code>"
            )
            bot.reply_to(message, msg, parse_mode="HTML")
        except Exception as e:
            bot.reply_to(message, "❌ Error al generar la Key.")
        return
        
    elif text == "🆔 Mi ID":
        bot.reply_to(message, f"🆔 <b>Tu ID de Telegram es:</b> <code>{uid}</code>", parse_mode="HTML")
        return

    elif text == "📊 Estado":
        ip = subprocess.getoutput("curl -s ipv4.icanhazip.com")
        ram = subprocess.getoutput("free -m | awk 'NR==2{printf \"%s / %s MB\", $3,$2}'")
        cpu = subprocess.getoutput("top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8}'")
        uptime = subprocess.getoutput("uptime -p")
        msg = f"📊 <b>ESTADO DEL VPS</b>\n\n🌐 <b>IP:</b> {ip}\n⚡ <b>RAM Uso:</b> {ram}\n🧠 <b>CPU Uso:</b> {cpu}%\n⏱ <b>Activo:</b> {uptime}"
        bot.reply_to(message, msg, parse_mode="HTML")
        return

    elif text == "🌐 Lista de IPs":
        ips = subprocess.getoutput("netstat -tn 2>/dev/null | grep :22 | awk '{print $5}' | cut -d: -f1 | sort | uniq")
        if not ips:
            ips = "Ninguna conexión detectada."
        bot.reply_to(message, f"🌐 <b>IPs Conectadas al SSH:</b>\n<code>{ips}</code>", parse_mode="HTML")
        return

    # ==========================
    # FUNCIONES EN DESARROLLO (Placeholders)
    # ==========================
    elif text in ["📁 Mis Dominios", "🌐 Dominio A", "🧩 Dominio NS", "📜 Mi Historial", "📈 Mi Uso", "➕ Add User", "🔍 Buscar ID", "📜 Logs Keys", "🏆 Ranking", "👥 Mis Clientes"]:
        bot.reply_to(message, f"⚙️ La función <b>{text}</b> requiere vincular el script de backend (Cloudflare/Database).", parse_mode="HTML")
        return

if __name__ == "__main__":
    while True:
        try:
            bot.infinity_polling(timeout=10, long_polling_timeout=5)
        except Exception as e:
            time.sleep(3)
EOF

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
systemctl stop vps-bot >/dev/null 2>&1
systemctl enable vps-bot >/dev/null 2>&1
systemctl restart vps-bot

echo -e "\n${C_GREEN}[✔] ¡Menú Maestro restaurado exitosamente!${C_NC}"
read -p "Presione Enter para regresar..."
