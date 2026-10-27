import os, subprocess, telebot, time, uuid, requests, datetime
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

AUTH_FILE = "/root/master_bot/auth_users.txt"
bot = telebot.TeleBot(TOKEN)

# COORDENADAS UNICODE
BTN_KEY_D = "\U0001F511 Key Due\u00f1o"
BTN_KEY_R = "\U0001F91D Key Revendedor"
BTN_KEY_CLIENT = "\U0001F511 Generar Key"
BTN_ESTADO = "\U0001F4CA Estado"
BTN_DOM_MIS = "\U0001F4C1 Mis Dominios"
BTN_DOM_A = "\U0001F310 Dominio A"
BTN_DOM_NS = "\U0001F9E9 Dominio NS"
BTN_HIST = "\U0001F4DC Mi Historial"
BTN_USO = "\U0001F4C8 Mi Uso"
BTN_ID = "\U0001F194 Mi ID"
BTN_ADD_USR = "\u2795 Add User"
BTN_FIND = "\U0001F50D Buscar ID"
BTN_LOGS = "\U0001F4DC Logs Keys"
BTN_RANK = "\U0001F3C6 Ranking"
BTN_CLIENTS = "\U0001F465 Mis Clientes"
BTN_IPS = "\U0001F310 Lista de IPs"

def load_auth():
    users = {}
    if os.path.exists(AUTH_FILE):
        with open(AUTH_FILE, "r") as f:
            for line in f:
                if ":" in line:
                    u, d = line.strip().split(":")
                    users[u] = d
    return users

def save_auth(users):
    with open(AUTH_FILE, "w") as f:
        for u, d in users.items():
            f.write(f"{u}:{d}\n")

def is_auth(uid):
    if uid == ADMIN_ID: return True
    users = load_auth()
    if uid in users:
        if datetime.datetime.now().strftime("%Y-%m-%d") <= users[uid]:
            return True
    return False

def get_keyboard():
    markup = types.ReplyKeyboardMarkup(row_width=2, resize_keyboard=True)
    markup.add(BTN_KEY_D, BTN_KEY_R)
    markup.add(BTN_ESTADO, BTN_DOM_MIS)
    markup.add(BTN_DOM_A, BTN_DOM_NS)
    markup.add(BTN_HIST, BTN_USO)
    markup.add(BTN_ID, BTN_ADD_USR)
    markup.add(BTN_FIND, BTN_LOGS)
    markup.add(BTN_RANK, BTN_CLIENTS)
    markup.add(BTN_IPS)
    return markup

def get_client_keyboard():
    markup = types.ReplyKeyboardMarkup(row_width=2, resize_keyboard=True)
    markup.add(BTN_KEY_CLIENT)
    markup.add(BTN_DOM_A, BTN_DOM_NS)
    markup.add(BTN_ID)
    return markup

def is_menu_button(text):
    return text in [BTN_KEY_D, BTN_KEY_R, BTN_KEY_CLIENT, BTN_ESTADO, BTN_DOM_MIS, BTN_DOM_A, BTN_DOM_NS, BTN_HIST, BTN_USO, BTN_ID, BTN_ADD_USR, BTN_FIND, BTN_LOGS, BTN_RANK, BTN_CLIENTS, BTN_IPS]

def cf_api_call(method, endpoint, data=None):
    url = f"https://api.cloudflare.com/client/v4/zones/{CF_ZONE}/{endpoint}"
    headers = {"X-Auth-Email": CF_EMAIL, "X-Auth-Key": CF_KEY, "Content-Type": "application/json"}
    if method == "POST": return requests.post(url, headers=headers, json=data)
    elif method == "GET": return requests.get(url, headers=headers)
    return None

def get_denied_msg(uid):
    return (
        "\u26A0\uFE0F <b>ACCESO DENEGADO</b> \u26A0\uFE0F\n"
        "━━━━━━━━━━━━━━━━━━━━\n"
        "No tienes permisos para utilizar este bot.\n\n"
        "Para adquirir acceso o servicios, contacta a:\n"
        "\U0001F468\u200D\U0001F4BB <b>Telegram:</b> @golbert_service\n"
        "\U0001F4DE <b>WhatsApp:</b> +51960084993\n"
        "━━━━━━━━━━━━━━━━━━━━\n"
        f"\U0001F194 <b>Tu ID es:</b> <code>{uid}</code>"
    )

@bot.message_handler(commands=['start'])
def send_welcome(message):
    uid = str(message.from_user.id)
    if uid == ADMIN_ID:
        bot.reply_to(message, "\U0001F451 <b>Bot Maestro Activo y Vinculado.</b>", parse_mode="HTML", reply_markup=get_keyboard())
    elif is_auth(uid):
        bot.reply_to(message, "\u2705 <b>Bienvenido Revendedor.</b>\nPuedes generar keys ilimitadas y vincular dominios hasta tu fecha de corte.", parse_mode="HTML", reply_markup=get_client_keyboard())
    else:
        bot.reply_to(message, get_denied_msg(uid), parse_mode="HTML")

@bot.message_handler(func=lambda message: True)
def handle_message(message):
    uid = str(message.from_user.id)
    if not is_auth(uid):
        bot.reply_to(message, get_denied_msg(uid), parse_mode="HTML")
        return
        
    text = message.text
    username = message.from_user.username or "Usuario"

    # === FUNCIONES COMPARTIDAS (ADMIN Y CLIENTE) ===
    if text == BTN_DOM_A:
        msg = bot.reply_to(message, "\U0001F310 <b>Crear Dominio A</b>\nIngresa el subdominio y la IP separados por espacio:\nEj: <code>vps1 192.168.1.1</code>", parse_mode="HTML")
        bot.register_next_step_handler(msg, process_domain_a)
        return
        
    elif text == BTN_DOM_NS:
        msg = bot.reply_to(message, "\U0001F9E9 <b>Crear Dominio NS</b>\nIngresa el subdominio y destino separados por espacio:\nEj: <code>ns1 vps1.dominio.com</code>", parse_mode="HTML")
        bot.register_next_step_handler(msg, process_domain_ns)
        return
        
    elif text == BTN_ID:
        if uid == ADMIN_ID:
            bot.reply_to(message, f"\U0001F194 <b>Tu ID:</b> <code>{uid}</code>\n\U0001F451 <b>Rol:</b> Due\u00f1o", parse_mode="HTML")
        else:
            exp_date = load_auth().get(uid, "Desconocido")
            bot.reply_to(message, f"\U0001F194 <b>Tu ID:</b> <code>{uid}</code>\n\u23F3 <b>Vence:</b> {exp_date}", parse_mode="HTML")
        return

    # === FUNCIONES EXCLUSIVAS DEL CLIENTE ===
    if uid != ADMIN_ID:
        if text == BTN_KEY_CLIENT:
            new_key = "VPS-" + str(uuid.uuid4()).upper().replace("-", "")[:12]
            new_key = f"{new_key[:4]}-{new_key[4:8]}-{new_key[8:12]}"
            exp_date = load_auth().get(uid, "Desconocido")
            msg = (
                "\u2705 <b>KEY GENERADA</b>\n"
                "━━━━━━━━━━━━━━━━━━━━\n"
                f"\U0001F464 <b>Vendedor:</b> @{username} (ID: <code>{uid}</code>)\n"
                f"\U0001F511 <b>Key:</b> <code>{new_key}</code>\n"
                f"\u23F3 <b>Tu panel vence:</b> {exp_date}\n"
                "━━━━━━━━━━━━━━━━━━━━\n"
                "\u26A0\uFE0F <b>Sistema:</b> Ubuntu 22.04|24.04|26.04\n"
                "\U0001F468\u200D\U0001F4BB <b>Due\u00f1o:</b> @golbertperuvps\n"
                "━━━━━━━━━━━━━━━━━━━━\n"
                "\U0001F4BB <b>Instalaci\u00f3n:</b>\n"
                "<code>apt update -y && apt install -y wget && wget -O install.sh https://raw.githubusercontent.com/golbert19/vps-script/main/install.sh && chmod +x install.sh && ./install.sh</code>"
            )
            bot.reply_to(message, msg, parse_mode="HTML")
        else:
            bot.reply_to(message, "\u26A0\uFE0F Utiliza los botones del men\u00fa.", reply_markup=get_client_keyboard())
        return

    # === FUNCIONES EXCLUSIVAS DEL ADMIN ===
    if text == BTN_KEY_D:
        new_key = "VPS-" + str(uuid.uuid4()).upper().replace("-", "")[:12]
        new_key = f"{new_key[:4]}-{new_key[4:8]}-{new_key[8:12]}"
        msg = (
            "\u2705 <b>KEY GENERADA (DUE\u00d1O)</b>\n"
            "━━━━━━━━━━━━━━━━━━━━\n"
            f"\U0001F464 <b>Cliente:</b> @{username} (ID: <code>{uid}</code>)\n"
            f"\U0001F511 <b>Key:</b> <code>{new_key}</code>\n"
            "\u23F3 <b>Vence:</b> Permanente\n"
            "━━━━━━━━━━━━━━━━━━━━\n"
            "\u26A0\uFE0F <b>Sistema:</b> Ubuntu 22.04|24.04|26.04\n"
            "\U0001F468\u200D\U0001F4BB <b>Due\u00f1o:</b> @golbertperuvps\n"
            "━━━━━━━━━━━━━━━━━━━━\n"
            "\U0001F4BB <b>Instalaci\u00f3n:</b>\n"
            "<code>apt update -y && apt install -y wget && wget -O install.sh https://raw.githubusercontent.com/golbert19/vps-script/main/install.sh && chmod +x install.sh && ./install.sh</code>"
        )
        bot.reply_to(message, msg, parse_mode="HTML")

    elif text == BTN_KEY_R:
        msg = bot.reply_to(message, "\U0001F91D <b>Key de Instalaci\u00f3n por D\u00edas</b>\nIngresa los <b>D\u00cdAS</b> de validez para esta instalaci\u00f3n.\nEjemplo: <code>30</code>", parse_mode="HTML")
        bot.register_next_step_handler(msg, process_key_revendedor)

    elif text == BTN_ADD_USR:
        msg = bot.reply_to(message, "\u2795 <b>Autorizar Revendedor al Bot</b>\nIngresa el ID de Telegram y los D\u00cdAS separados por espacio:\nEjemplo: <code>123456789 30</code>", parse_mode="HTML")
        bot.register_next_step_handler(msg, process_add_user)

    elif text == BTN_CLIENTS:
        users = load_auth()
        if not users:
            bot.reply_to(message, "\u26A0\uFE0F No tienes revendedores autorizados.", parse_mode="HTML")
        else:
            res = "\U0001F465 <b>REVENDEDORES AUTORIZADOS</b>\n━━━━━━━━━━━━━━━━━━━━\n"
            for u, d in users.items():
                res += f"\U0001F194 ID: <code>{u}</code> \u279C Vence: {d}\n"
            bot.reply_to(message, res, parse_mode="HTML")
            
    elif text == BTN_ESTADO:
        ip = subprocess.getoutput("curl -s ipv4.icanhazip.com")
        ram = subprocess.getoutput("free -m | awk 'NR==2{printf \"%s / %s MB\", $3,$2}'")
        bot.reply_to(message, f"\U0001F4CA <b>ESTADO</b>\n\U0001F310 <b>IP:</b> {ip}\n\u26A1 <b>RAM:</b> {ram}", parse_mode="HTML")
        
    elif text == BTN_IPS:
        ips = subprocess.getoutput("netstat -tn 2>/dev/null | grep :22 | awk '{print $5}' | cut -d: -f1 | sort | uniq")
        if not ips: ips = "Ninguna conexi\u00f3n activa."
        bot.reply_to(message, f"\U0001F310 <b>IPs Conectadas:</b>\n<code>{ips}</code>", parse_mode="HTML")

# --- PROCESADORES INTERNOS ---
def process_add_user(message):
    if is_menu_button(message.text): return handle_message(message)
    try:
        target_id, days = message.text.split()
        days = int(days)
        exp_date = (datetime.datetime.now() + datetime.timedelta(days=days)).strftime("%Y-%m-%d")
        
        users = load_auth()
        users[target_id] = exp_date
        save_auth(users)
        
        bot.reply_to(message, f"\u2705 <b>ACCESO AL BOT CONCEDIDO</b>\n\U0001F194 <b>ID Autorizado:</b> <code>{target_id}</code>\n\u23F3 <b>Vence:</b> {exp_date} ({days} d\u00edas)\n\nEl cliente ya puede entrar al bot, darle /start y generar sus propias keys y dominios.", parse_mode="HTML")
    except: 
        bot.reply_to(message, "\u274C Formato incorrecto. Usa: ID DIAS\nEjemplo: <code>123456789 30</code>", parse_mode="HTML")

def process_key_revendedor(message):
    if is_menu_button(message.text): return handle_message(message)
    try:
        days = int(message.text.strip())
        new_key = "VPS-" + str(uuid.uuid4()).upper().replace("-", "")[:12]
        new_key = f"{new_key[:4]}-{new_key[4:8]}-{new_key[8:12]}"
        exp_date = (datetime.datetime.now() + datetime.timedelta(days=days)).strftime("%Y-%m-%d")
        username = message.from_user.username or "Usuario"
        msg = (
            "\u2705 <b>KEY DE INSTALACI\u00d3N CREADA</b>\n"
            "━━━━━━━━━━━━━━━━━━━━\n"
            f"\U0001F464 <b>Cliente:</b> @{username} (ID: <code>{message.from_user.id}</code>)\n"
            f"\U0001F511 <b>Key:</b> <code>{new_key}</code>\n"
            f"\u23F3 <b>Vence:</b> {exp_date} ({days} D\u00edas)\n"
            "━━━━━━━━━━━━━━━━━━━━\n"
            "\u26A0\uFE0F <b>Sistema:</b> Ubuntu 22.04|24.04|26.04\n"
            "\U0001F468\u200D\U0001F4BB <b>Due\u00f1o:</b> @golbertperuvps\n"
            "━━━━━━━━━━━━━━━━━━━━\n"
            "\U0001F4BB <b>Instalaci\u00f3n:</b>\n"
            "<code>apt update -y && apt install -y wget && wget -O install.sh https://raw.githubusercontent.com/golbert19/vps-script/main/install.sh && chmod +x install.sh && ./install.sh</code>"
        )
        bot.reply_to(message, msg, parse_mode="HTML")
    except ValueError:
        bot.reply_to(message, "\u274C Error. Ingresa solo un n\u00famero (Ej: 30).", parse_mode="HTML")

def process_domain_a(message):
    if is_menu_button(message.text): return handle_message(message)
    try:
        sub, ip = message.text.split()
        full_domain = f"{sub}.{DOMAIN}"
        data = {"type": "A", "name": full_domain, "content": ip, "ttl": 1, "proxied": False}
        resp = cf_api_call("POST", "dns_records", data)
        if resp and resp.status_code == 200:
            bot.reply_to(message, f"\u2705 <b>Dominio A Creado</b>\n\U0001F310 {full_domain} -> {ip}", parse_mode="HTML")
        else:
            bot.reply_to(message, f"\u274C Error API Cloudflare:\n{resp.text if resp else 'Sin conexi\u00f3n'}")
    except: bot.reply_to(message, "\u274C Error de formato. Usa: subdominio IP")

def process_domain_ns(message):
    if is_menu_button(message.text): return handle_message(message)
    try:
        sub, target = message.text.split()
        full_domain = f"{sub}.{DOMAIN}"
        data = {"type": "NS", "name": full_domain, "content": target, "ttl": 1, "proxied": False}
        resp = cf_api_call("POST", "dns_records", data)
        if resp and resp.status_code == 200:
            bot.reply_to(message, f"\u2705 <b>Dominio NS Creado</b>\n\U0001F9E9 {full_domain} -> {target}", parse_mode="HTML")
        else:
            bot.reply_to(message, f"\u274C Error API Cloudflare:\n{resp.text if resp else 'Sin conexi\u00f3n'}")
    except: bot.reply_to(message, "\u274C Error de formato. Usa: subdominio destino")

if __name__ == "__main__":
    while True:
        try: bot.infinity_polling(timeout=10, long_polling_timeout=5)
        except: time.sleep(3)
