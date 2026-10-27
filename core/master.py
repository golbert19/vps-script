import os, subprocess, telebot, time, uuid, requests
from telebot import types

# Cargar Configuración
config = {}
with open("/root/master_bot/config.env", "r") as f:
    for line in f:
        if "=" in line:
            k, v = line.strip().split("=", 1)
            config[k] = v.strip('"')

TOKEN = config.get("TOKEN", "")
ADMIN_ID = config.get("ADMIN", "")
CF_EMAIL = config.get("CF_EMAIL", "")
CF_KEY = config.get("CF_KEY", "")
CF_ZONE = config.get("CF_ZONE", "")
DOMAIN = config.get("DOMAIN", "")

bot = telebot.TeleBot(TOKEN)

def get_keyboard():
    markup = types.ReplyKeyboardMarkup(row_width=2, resize_keyboard=True)
    # Se eliminaron Key Auto, Key Manual e Instalar VPS. Se agregó Generar key centralizado.
    markup.add("🔑 Generar key")
    markup.add("📊 Estado", "📁 Mis Dominios")
    markup.add("🌐 Dominio A", "🧩 Dominio NS")
    markup.add("📜 Mi Historial", "📈 Mi Uso")
    markup.add("🆔 Mi ID", "➕ Add User")
    markup.add("🔍 Buscar ID", "📜 Logs Keys")
    markup.add("🏆 Ranking", "👥 Mis Clientes")
    markup.add("🌐 Lista de IPs")
    return markup

def cf_api_call(method, endpoint, data=None):
    url = f"https://api.cloudflare.com/client/v4/zones/{CF_ZONE}/{endpoint}"
    headers = {
        "X-Auth-Email": CF_EMAIL,
        "X-Auth-Key": CF_KEY,
        "Content-Type": "application/json"
    }
    if method == "POST":
        return requests.post(url, headers=headers, json=data)
    elif method == "GET":
        return requests.get(url, headers=headers)
    return None

@bot.message_handler(commands=['start'])
def send_welcome(message):
    uid = str(message.from_user.id)
    if uid == ADMIN_ID:
        bot.reply_to(message, "👑 <b>Bot Maestro Activo y Vinculado.</b>", parse_mode="HTML", reply_markup=get_keyboard())
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
    username = message.from_user.username or "Usuario"

    # ==========================================
    # GESTIÓN DE CLOUDFLARE
    # ==========================================
    if text == "🌐 Dominio A":
        msg = bot.reply_to(message, "🌐 <b>Crear Dominio A</b>\nIngresa el subdominio y la IP separados por un espacio.\nEjemplo: <code>vps1 192.168.1.1</code>", parse_mode="HTML")
        bot.register_next_step_handler(msg, process_domain_a)
        
    elif text == "🧩 Dominio NS":
        msg = bot.reply_to(message, "🧩 <b>Crear Dominio NS</b>\nIngresa el subdominio NS y el destino (ej. servidor A) separados por espacio.\nEjemplo: <code>ns1 vps1.tudominio.com</code>", parse_mode="HTML")
        bot.register_next_step_handler(msg, process_domain_ns)

    # ==========================================
    # GENERADOR DE KEY PREMIUM
    # ==========================================
    elif text == "🔑 Generar key":
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

    # ==========================================
    # GESTIÓN DE USUARIOS
    # ==========================================
    elif text == "➕ Add User":
        msg = bot.reply_to(message, "➕ <b>Crear Usuario SSH</b>\nIngresa los datos separados por espacio:\n<code>[usuario] [clave] [días]</code>\nEjemplo: <code>carlos 1234 30</code>", parse_mode="HTML")
        bot.register_next_step_handler(msg, process_add_user)

    # ==========================================
    # UTILIDADES
    # ==========================================
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

# --- Funciones de Procesamiento Continuo ---
def process_domain_a(message):
    try:
        sub, ip = message.text.split()
        full_domain = f"{sub}.{DOMAIN}"
        data = {"type": "A", "name": full_domain, "content": ip, "ttl": 1, "proxied": False}
        resp = cf_api_call("POST", "dns_records", data)
        if resp and resp.status_code == 200:
            bot.reply_to(message, f"✅ <b>Dominio A Creado</b>\n🌐 {full_domain} -> {ip}", parse_mode="HTML")
        else:
            bot.reply_to(message, f"❌ Error API Cloudflare:\n{resp.text if resp else 'Sin conexión'}")
    except Exception as e:
        bot.reply_to(message, "❌ Error de formato. Usa: subdominio IP")

def process_domain_ns(message):
    try:
        sub, target = message.text.split()
        full_domain = f"{sub}.{DOMAIN}"
        data = {"type": "NS", "name": full_domain, "content": target, "ttl": 1, "proxied": False}
        resp = cf_api_call("POST", "dns_records", data)
        if resp and resp.status_code == 200:
            bot.reply_to(message, f"✅ <b>Dominio NS Creado</b>\n🧩 {full_domain} -> {target}", parse_mode="HTML")
        else:
            bot.reply_to(message, f"❌ Error API Cloudflare:\n{resp.text if resp else 'Sin conexión'}")
    except Exception as e:
        bot.reply_to(message, "❌ Error de formato. Usa: subdominio destino")

def process_add_user(message):
    try:
        user, pwd, days = message.text.split()
        res_cmd = subprocess.getoutput(f"useradd -e $(date -d '+{days} days' +'%Y-%m-%d') -s /bin/false -M {user} && echo '{user}:{pwd}' | chpasswd")
        if "already exists" in res_cmd:
            bot.reply_to(message, "❌ El usuario ya existe.")
            return
        exp_date = subprocess.getoutput(f"date -d '+{days} days' +'%Y-%m-%d'")
        subprocess.getoutput(f"cat /etc/issue.net > /etc/vps-manager/banner_{user}.net && echo \"<br><font color='cyan'>=======================</font><br><font color='yellow'>👤 Usuario:</font> <font color='white'>{user}</font><br><font color='yellow'>📅 Expira:</font> <font color='white'>{exp_date} ({days} Días)</font><br><font color='cyan'>=======================</font><br>\" >> /etc/vps-manager/banner_{user}.net && sed -i '/Match User {user}/d' /etc/ssh/sshd_config && echo -e '\\nMatch User {user}\\nBanner /etc/vps-manager/banner_{user}.net' >> /etc/ssh/sshd_config && systemctl restart ssh")
        
        bot.reply_to(message, f"✅ <b>CUENTA SSH CREADA</b>\n👤 <code>{user}</code>\n🔑 <code>{pwd}</code>\n📅 {exp_date} ({days} días)", parse_mode="HTML")
    except Exception as e:
        bot.reply_to(message, "❌ Formato incorrecto.")

if __name__ == "__main__":
    while True:
        try: bot.infinity_polling(timeout=10, long_polling_timeout=5)
        except: time.sleep(3)
        
