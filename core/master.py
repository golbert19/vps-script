#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import subprocess
import telebot
import time
import uuid
import requests
import datetime
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
CREDITS_FILE = "/root/master_bot/credits.txt"
KEYS_FILE = "/root/master_bot/keys_db.txt"
bot = telebot.TeleBot(TOKEN)

# BOTONES EN TEXTO LIMPIO (SIN EMOJIS PROBLEMÁTICOS)
BTN_KEY_D = "Key Dueno"
BTN_BROADCAST = "Mensaje"
BTN_KEY_CLIENT = "Generar Key"
BTN_ESTADO = "Estado"
BTN_DOM_MIS = "Mis Dominios"
BTN_DOM_A = "Dominio A"
BTN_DOM_NS = "Dominio NS"
BTN_HIST = "Mi Historial"
BTN_USO = "Mi Uso"
BTN_ID = "Mi ID"
BTN_ADD_USR = "Add User"
BTN_RENEW = "Renovar Acceso"
BTN_DEL = "Eliminar Acceso"
BTN_FIND = "Buscar ID"
BTN_LOGS = "Logs Keys"
BTN_RANK = "Ranking"
BTN_CLIENTS = "Mis Clientes"
BTN_IPS = "Lista de IPs"

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

def load_credits():
    creds = {}
    if os.path.exists(CREDITS_FILE):
        with open(CREDITS_FILE, "r") as f:
            for line in f:
                if ":" in line:
                    u, c = line.strip().split(":")
                    creds[u] = int(c)
    return creds

def save_credits(creds):
    with open(CREDITS_FILE, "w") as f:
        for u, c in creds.items():
            f.write(f"{u}:{c}\n")

def save_key_owner(key, owner_id):
    with open(KEYS_FILE, "a") as f:
        f.write(f"{key}:{owner_id}\n")

def check_and_burn_key(key):
    if not os.path.exists(KEYS_FILE):
        return None
    lines = []
    owner_id = None
    with open(KEYS_FILE, "r") as f:
        for line in f:
            parts = line.strip().split(":")
            if len(parts) == 2:
                k, o = parts
                if k == key:
                    owner_id = o
                else:
                    lines.append(line)
    if owner_id:
        with open(KEYS_FILE, "w") as f:
            f.writelines(lines)
    return owner_id

def notify_key_usage(key_used, vps_ip="Desconocida"):
    owner_id = check_and_burn_key(key_used)
    if owner_id:
        try:
            bot.send_message(
                owner_id,
                "AVISO DE KEY USADA:\n"
                f"Key: {key_used}\n"
                f"Instalada en IP: {vps_ip}"
            )
        except Exception as e:
            print(f"Error: {e}")

def is_auth(uid):
    if uid == ADMIN_ID: return True
    users = load_auth()
    if uid in users:
        if datetime.datetime.now().strftime("%Y-%m-%d") <= users[uid]:
            return True
    return False

def get_keyboard():
    markup = types.ReplyKeyboardMarkup(row_width=2, resize_keyboard=True)
    markup.add(BTN_KEY_D, BTN_BROADCAST)
    markup.add(BTN_ADD_USR, BTN_RENEW, BTN_DEL)
    markup.add(BTN_FIND, BTN_CLIENTS)
    markup.add(BTN_ESTADO, BTN_IPS)
    markup.add(BTN_DOM_MIS, BTN_DOM_A, BTN_DOM_NS)
    markup.add(BTN_HIST, BTN_USO, BTN_LOGS, BTN_RANK)
    markup.add(BTN_ID)
    return markup

def get_client_keyboard():
    markup = types.ReplyKeyboardMarkup(row_width=2, resize_keyboard=True)
    markup.add(BTN_KEY_CLIENT)
    markup.add(BTN_ADD_USR, BTN_RENEW, BTN_DEL)
    markup.add(BTN_FIND, BTN_DOM_A, BTN_DOM_NS)
    markup.add(BTN_ID)
    return markup

def is_menu_button(text):
    return text in [BTN_KEY_D, BTN_BROADCAST, BTN_KEY_CLIENT, BTN_ESTADO, BTN_DOM_MIS, BTN_DOM_A, BTN_DOM_NS, BTN_HIST, BTN_USO, BTN_ID, BTN_ADD_USR, BTN_RENEW, BTN_DEL, BTN_FIND, BTN_LOGS, BTN_RANK, BTN_CLIENTS, BTN_IPS]

def cf_api_call(method, endpoint, data=None):
    url = f"https://api.cloudflare.com/client/v4/zones/{CF_ZONE}/{endpoint}"
    headers = {"X-Auth-Email": CF_EMAIL, "X-Auth-Key": CF_KEY, "Content-Type": "application/json"}
    if method == "POST": return requests.post(url, headers=headers, json=data)
    elif method == "GET": return requests.get(url, headers=headers)
    return None

def get_denied_msg(uid):
    return f"ACCESO DENEGADO\nTu ID es: {uid}"

@bot.message_handler(commands=['start'])
def send_welcome(message):
    uid = str(message.from_user.id)
    if uid == ADMIN_ID:
        bot.reply_to(message, "Bot Maestro Activo.", reply_markup=get_keyboard())
    elif is_auth(uid):
        bot.reply_to(message, "Bienvenido Revendedor.", reply_markup=get_client_keyboard())
    else:
        bot.reply_to(message, get_denied_msg(uid))

@bot.message_handler(func=lambda message: True)
def handle_message(message):
    uid = str(message.from_user.id)
    if not is_auth(uid):
        bot.reply_to(message, get_denied_msg(uid))
        return
        
    text = message.text
    username = message.from_user.username or "Usuario"

    if text == BTN_DOM_A:
        msg = bot.reply_to(message, f"Crear Dominio A ({DOMAIN})\nIngresa subdominio e IP:")
        bot.register_next_step_handler(msg, process_domain_a)
        return
        
    elif text == BTN_DOM_NS:
        msg = bot.reply_to(message, f"Crear Dominio NS ({DOMAIN})\nIngresa subdominio y destino:")
        bot.register_next_step_handler(msg, process_domain_ns)
        return
        
    elif text == BTN_ID:
        if uid == ADMIN_ID:
            bot.reply_to(message, f"Tu ID: {uid} (Dueño)")
        else:
            exp_date = load_auth().get(uid, "Desconocido")
            creds = load_credits().get(uid, 0)
            bot.reply_to(message, f"Tu ID: {uid}\nVence: {exp_date}\nCréditos: {creds}")
        return

    elif text == BTN_ADD_USR:
        if uid == ADMIN_ID:
            msg = bot.reply_to(message, "Autorizar Revendedor (ID CREDITOS):")
            bot.register_next_step_handler(msg, process_add_revendedor)
        else:
            msg = bot.reply_to(message, "Autorizar Cliente (ID DIAS):")
            bot.register_next_step_handler(msg, process_add_cliente)
        return

    elif text == BTN_RENEW:
        if uid == ADMIN_ID:
            msg = bot.reply_to(message, "Renovar Revendedor (ID CREDITOS):")
            bot.register_next_step_handler(msg, process_renew_revendedor)
        else:
            msg = bot.reply_to(message, "Renovar Cliente (ID DIAS):")
            bot.register_next_step_handler(msg, process_renew_cliente)
        return

    elif text == BTN_DEL:
        msg = bot.reply_to(message, "Eliminar Acceso (Ingresa ID):")
        bot.register_next_step_handler(msg, process_del_user)
        return

    elif text == BTN_FIND:
        msg = bot.reply_to(message, "Buscar ID:")
        bot.register_next_step_handler(msg, process_find_user)
        return

    if uid != ADMIN_ID:
        if text == BTN_KEY_CLIENT:
            new_key = "VPS-" + str(uuid.uuid4()).upper().replace("-", "")[:12]
            new_key = f"{new_key[:4]}-{new_key[4:8]}-{new_key[8:12]}"
            save_key_owner(new_key, uid)
            exp_date = load_auth().get(uid, "Desconocido")
            msg = f"KEY GENERADA\nVendedor: @{username}\nKey: {new_key}\nVence: {exp_date}"
            bot.reply_to(message, msg)
        else:
            bot.reply_to(message, "Utiliza los botones del menú.", reply_markup=get_client_keyboard())
        return

    if text == BTN_KEY_D:
        new_key = "VPS-" + str(uuid.uuid4()).upper().replace("-", "")[:12]
        new_key = f"{new_key[:4]}-{new_key[4:8]}-{new_key[8:12]}"
        save_key_owner(new_key, uid)
        msg = f"KEY GENERADA (DUEÑO)\nKey: {new_key}\nVence: Permanente"
        bot.reply_to(message, msg)

    elif text == BTN_BROADCAST:
        msg = bot.reply_to(message, "Envía el mensaje masivo para todos los usuarios:")
        bot.register_next_step_handler(msg, process_broadcast)
        return

    elif text == BTN_DOM_MIS:
        resp = cf_api_call("GET", "dns_records")
        if resp and resp.status_code == 200:
            records = resp.json().get("result", [])
            res = "Registros DNS:\n"
            for r in records[:20]:
                res += f"- {r.get('type')}: {r.get('name')} -> {r.get('content')}\n"
            bot.reply_to(message, res)
        else:
            bot.reply_to(message, "Error al consultar Cloudflare.")

    elif text == BTN_CLIENTS:
        users = load_auth()
        creds = load_credits()
        res = "Usuarios Autorizados:\n"
        for u, d in users.items():
            res += f"ID: {u} | Vence: {d} | Créditos: {creds.get(u, 0)}\n"
        bot.reply_to(message, res)
            
    elif text == BTN_ESTADO:
        ip = subprocess.getoutput("curl -s ipv4.icanhazip.com")
        ram = subprocess.getoutput("free -m | awk 'NR==2{printf \"%s / %s MB\", $3,$2}'")
        bot.reply_to(message, f"Estado VPS - IP: {ip} | RAM: {ram}")
        
    elif text == BTN_IPS:
        ips = subprocess.getoutput("netstat -tn 2>/dev/null | grep :22 | awk '{print $5}' | cut -d: -f1 | sort | uniq")
        bot.reply_to(message, f"IPs Conectadas:\n{ips}")

def process_add_revendedor(message):
    if is_menu_button(message.text): return handle_message(message)
    try:
        target_id, creditos = message.text.split()
        users = load_auth()
        creds = load_credits()
        users[target_id] = (datetime.datetime.now() + datetime.timedelta(days=365)).strftime("%Y-%m-%d")
        creds[target_id] = creds.get(target_id, 0) + int(creditos)
        save_auth(users); save_credits(creds)
        bot.reply_to(message, f"Revendedor añadido con éxito.")
    except: bot.reply_to(message, "Formato incorrecto.")

def process_add_cliente(message):
    uid = str(message.from_user.id)
    if is_menu_button(message.text): return handle_message(message)
    try:
        target_id, days = message.text.split()
        creds = load_credits()
        if creds.get(uid, 0) < 1:
            bot.reply_to(message, "Fondos insuficientes.")
            return
        creds[uid] -= 1
        save_credits(creds)
        users = load_auth()
        users[target_id] = (datetime.datetime.now() + datetime.timedelta(days=int(days))).strftime("%Y-%m-%d")
        save_auth(users)
        bot.reply_to(message, f"Cliente autorizado con éxito.")
    except: bot.reply_to(message, "Formato incorrecto.")

def process_renew_revendedor(message):
    if is_menu_button(message.text): return handle_message(message)
    try:
        target_id, creditos = message.text.split()
        creds = load_credits()
        creds[target_id] = creds.get(target_id, 0) + int(creditos)
        save_credits(creds)
        bot.reply_to(message, "Créditos actualizados.")
    except: bot.reply_to(message, "Formato incorrecto.")

def process_renew_cliente(message):
    uid = str(message.from_user.id)
    if is_menu_button(message.text): return handle_message(message)
    try:
        target_id, days = message.text.split()
        creds = load_credits()
        if creds.get(uid, 0) < 1:
            bot.reply_to(message, "Fondos insuficientes.")
            return
        creds[uid] -= 1
        save_credits(creds)
        users = load_auth()
        current_exp = datetime.datetime.strptime(users[target_id], "%Y-%m-%d")
        if current_exp < datetime.datetime.now(): current_exp = datetime.datetime.now()
        users[target_id] = (current_exp + datetime.timedelta(days=int(days))).strftime("%Y-%m-%d")
        save_auth(users)
        bot.reply_to(message, "Cliente renovado.")
    except: bot.reply_to(message, "Formato incorrecto.")

def process_del_user(message):
    if is_menu_button(message.text): return handle_message(message)
    target_id = message.text.strip()
    users = load_auth()
    if target_id in users:
        del users[target_id]; save_auth(users)
        bot.reply_to(message, "Usuario eliminado.")
    else: bot.reply_to(message, "Usuario no encontrado.")

def process_find_user(message):
    if is_menu_button(message.text): return handle_message(message)
    target_id = message.text.strip()
    users = load_auth()
    creds = load_credits()
    if target_id in users:
        bot.reply_to(message, f"ID: {target_id}\nVence: {users[target_id]}\nCréditos: {creds.get(target_id, 0)}")
    else: bot.reply_to(message, "No registrado.")

def process_broadcast(message):
    if is_menu_button(message.text): return handle_message(message)
    announcement = message.text
    users = load_auth()
    count = 0
    for target_id in users.keys():
        try:
            bot.send_message(target_id, f"AVISO IMPORTANTE:\n{announcement}")
            count += 1
        except: pass
    bot.reply_to(message, f"Mensaje enviado a {count} usuarios.")

def process_domain_a(message):
    if is_menu_button(message.text): return handle_message(message)
    try:
        sub, ip = message.text.split()
        full_domain = f"{sub}.{DOMAIN}"
        data = {"type": "A", "name": full_domain, "content": ip, "ttl": 1, "proxied": False}
        resp = cf_api_call("POST", "dns_records", data=data)
        if resp and resp.status_code == 200: bot.reply_to(message, f"Dominio A creado: {full_domain}")
        else: bot.reply_to(message, "Error en Cloudflare.")
    except: bot.reply_to(message, "Formato incorrecto.")

def process_domain_ns(message):
    if is_menu_button(message.text): return handle_message(message)
    try:
        sub, target = message.text.split()
        full_domain = f"{sub}.{DOMAIN}"
        data = {"type": "NS", "name": full_domain, "content": target, "ttl": 1, "proxied": False}
        resp = cf_api_call("POST", "dns_records", data=data)
        if resp and resp.status_code == 200: bot.reply_to(message, f"Dominio NS creado: {full_domain}")
        else: bot.reply_to(message, "Error en Cloudflare.")
    except: bot.reply_to(message, "Formato incorrecto.")

while True:
    try:
        bot.polling(none_stop=True)
    except Exception as e:
        time.sleep(5)
