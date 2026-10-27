import os, subprocess, telebot, time, uuid
from telebot import types

TOKEN, ADMIN_ID = "", ""
with open("/root/master_bot/config.env", "r") as f:
    for line in f:
        if line.startswith("TOKEN="): TOKEN = line.split("=")[1].strip().strip('"')
        elif line.startswith("ADMIN="): ADMIN_ID = line.split("=")[1].strip().strip('"')

bot = telebot.TeleBot(TOKEN)

@bot.message_handler(commands=['start', 'help'])
def send_welcome(message):
    uid = str(message.from_user.id)
    if uid == ADMIN_ID:
        markup = types.ReplyKeyboardMarkup(row_width=2, resize_keyboard=True)
        markup.add("📊 Estado", "📁 Mis Dominios")
        markup.add("🌐 Dominio A", "🧩 Dominio NS")
        markup.add("🔑 Generar key") 
        markup.add("📜 Mi Historial", "📈 Mi Uso")
        markup.add("🆔 Mi ID")
        markup.add("➕ Add User", "🔍 Buscar ID")
        markup.add("📜 Logs Keys", "🏆 Ranking")
        markup.add("👥 Mis Clientes", "🌐 Lista de IPs")
        bot.reply_to(message, "👑 <b>Bot Maestro Activo</b>", parse_mode="HTML", reply_markup=markup)
    else:
        msg = (
            "⚠️ <b>ACCESO DENEGADO</b> ⚠️\n"
            "━━━━━━━━━━━━━━━━━━━━\n"
            "No tienes permisos para utilizar este bot.\n\n"
            "Para adquirir acceso o servicios, contacta a:\n"
            "👨‍💻 <b>Telegram:</b> @golbert_service\n"
            "📞 <b>WhatsApp:</b> +51960084993\n"
            "━━━━━━━━━━━━━━━━━━━━\n"
            f"🆔 <b>Tu ID es:</b> <code>{uid}</code>"
        )
        bot.reply_to(message, msg, parse_mode="HTML")

@bot.message_handler(func=lambda message: True)
def handle_message(message):
    uid = str(message.from_user.id)
    
    if uid != ADMIN_ID:
        msg = (
            "⚠️ <b>ACCESO DENEGADO</b> ⚠️\n"
            "━━━━━━━━━━━━━━━━━━━━\n"
            "No tienes permisos para utilizar este bot.\n\n"
            "Para adquirir acceso o servicios, contacta a:\n"
            "👨‍💻 <b>Telegram:</b> @golbert_service\n"
            "📞 <b>WhatsApp:</b> +51960084993\n"
            "━━━━━━━━━━━━━━━━━━━━\n"
            f"🆔 <b>Tu ID es:</b> <code>{uid}</code>"
        )
        bot.reply_to(message, msg, parse_mode="HTML")
        return
        
    text = message.text
    username = message.from_user.username if message.from_user.username else "Usuario"

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
                "👨‍💻 <b>Dueño:</b> @golbert_service\n"
                "━━━━━━━━━━━━━━━━━━━━\n"
                "💻 <b>Instalación:</b>\n"
                "<code>apt update -y && apt install -y wget && wget -O install.sh https://raw.githubusercontent.com/golbert19/vps-script/main/install.sh && chmod +x install.sh && ./install.sh</code>"
            )
            bot.reply_to(message, msg, parse_mode="HTML")
        except: bot.reply_to(message, "❌ Error.")
        
    elif text == "🆔 Mi ID":
        bot.reply_to(message, f"🆔 <b>Tu ID:</b> <code>{uid}</code>", parse_mode="HTML")
    elif text == "📊 Estado":
        ip = subprocess.getoutput("curl -s ipv4.icanhazip.com")
        ram = subprocess.getoutput("free -m | awk 'NR==2{printf \"%s / %s MB\", $3,$2}'")
        bot.reply_to(message, f"📊 <b>ESTADO</b>\n🌐 <b>IP:</b> {ip}\n⚡ <b>RAM:</b> {ram}", parse_mode="HTML")
    elif text == "🌐 Lista de IPs":
        ips = subprocess.getoutput("netstat -tn 2>/dev/null | grep :22 | awk '{print $5}' | cut -d: -f1 | sort | uniq")
        if not ips: ips = "Ninguna conexión activa."
        bot.reply_to(message, f"🌐 <b>IPs Conectadas:</b>\n<code>{ips}</code>", parse_mode="HTML")
    else:
        bot.reply_to(message, f"⚙️ La función <b>{text}</b> requiere el backend de Base de Datos o Cloudflare.", parse_mode="HTML")

if __name__ == "__main__":
    while True:
        try: bot.infinity_polling(timeout=10, long_polling_timeout=5)
        except: time.sleep(3)
            
