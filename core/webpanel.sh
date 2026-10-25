#!/bin/bash
# ==========================================
# Módulo: Panel Web Ultra PRO (Estilo Natben)
# ==========================================
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
WEB_DIR="/etc/vps-manager/webpanel"

clear
echo -e "${C_CYAN}================================================${C_NC}"
echo -e "${C_GREEN}    INSTALADOR WEB PANEL PRO (DARK UI)          ${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"

read -p "Crea un Usuario para el Panel Web: " WEB_USER
read -p "Crea una Contraseña para el Panel Web: " WEB_PASS

echo -e "${C_YELLOW}[+] Instalando servidor web nativo...${C_NC}"
apt update -y >/dev/null 2>&1
apt install -y python3 python3-pip python3-venv >/dev/null 2>&1

mkdir -p "$WEB_DIR"
cd "$WEB_DIR"

rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install Flask >/dev/null 2>&1

# ==========================================
# CÓDIGO PYTHON / FLASK Y DISEÑO HTML
# ==========================================
cat << 'EOF' > "$WEB_DIR/app.py"
from flask import Flask, render_template_string, request, Response, redirect, url_for
import subprocess
import os

app = Flask(__name__)

# Configuración inyectada desde Bash
USER = "REPLACE_USER"
PASS = "REPLACE_PASS"

def check_auth(username, password):
    return username == USER and password == PASS

def authenticate():
    return Response(
    '<html><body style="background:#0a0e17;color:white;text-align:center;font-family:sans-serif;margin-top:50px;">'
    '<h2>Acceso Denegado</h2><p>Debes iniciar sesión con las credenciales de tu VPS.</p></body></html>', 401,
    {'WWW-Authenticate': 'Basic realm="GOLBERT VPS PANEL"'})

def requires_auth(f):
    def decorated(*args, **kwargs):
        auth = request.authorization
        if not auth or not check_auth(auth.username, auth.password):
            return authenticate()
        return f(*args, **kwargs)
    decorated.__name__ = f.__name__
    return decorated

@app.route('/')
@requires_auth
def index():
    # Obtener usuarios SSH
    user_list_cmd = "awk -F: '$3 >= 1000 && $1 != \"nobody\" {print $1}' /etc/passwd"
    users_raw = subprocess.getoutput(user_list_cmd).split('\n')
    
    total_users = 0
    online_count = 0
    blocked_count = 0
    expirados_count = 0
    
    user_cards = ""
    
    for u in users_raw:
        if not u.strip(): continue
        total_users += 1
        
        # Obtener Fecha Exp
        exp_date = subprocess.getoutput(f"chage -l {u} | grep 'Account expires' | awk -F': ' '{{print $2}}'")
        if "never" in exp_date.lower() or not exp_date.strip():
            dias_restantes = "Ilimitado"
            badge = "CLIENTE"
            badge_color = "#28a745"
        else:
            sec_exp = int(subprocess.getoutput(f"date -d '{exp_date}' +%s 2>/dev/null || echo 0"))
            sec_now = int(subprocess.getoutput("date +%s"))
            dias = int((sec_exp - sec_now) / 86400)
            if dias <= 0:
                dias_restantes = "Expirado"
                expirados_count += 1
                badge = "EXPIRADO"
                badge_color = "#dc3545"
            elif dias <= 2:
                dias_restantes = f"{dias} Días"
                badge = "DEMO"
                badge_color = "#fd7e14"
            else:
                dias_restantes = f"{dias} Días"
                badge = "CLIENTE"
                badge_color = "#28a745"

        # Verificar si está bloqueado
        is_locked = "!" in subprocess.getoutput(f"grep '^{u}:' /etc/shadow | cut -d: -f2")
        status_text = "OFFLINE"
        status_color = "#6c757d"
        
        if is_locked:
            status_text = "BLOCKED"
            status_color = "#dc3545"
            blocked_count += 1
            action_btn = f'<a href="/action/unlock/{u}" class="btn btn-warning">🔓 Desbloq.</a>'
        else:
            # Verificar si está online
            conns = int(subprocess.getoutput(f"ps -ef | grep sshd | grep '{u}' | grep -v root | grep -v grep | wc -l"))
            if conns > 0:
                status_text = "ONLINE"
                status_color = "#28a745"
                online_count += 1
            action_btn = f'<a href="/action/lock/{u}" class="btn btn-danger">🚫 Bloquear</a>'

        user_cards += f"""
        <div class="user-card">
            <div class="user-header">
                <h2>{u}</h2>
                <span class="badge" style="color: {badge_color}">{badge}</span>
            </div>
            <p style="color: #8c9baf; font-size: 12px; margin-bottom: 15px;">SSH / VPN</p>
            <p>Estado: <strong style="color:{status_color}">{status_text}</strong></p>
            <p>Tiempo restante: <strong>{dias_restantes}</strong></p>
            <div class="card-actions">
                <a href="/action/renew/{u}" class="btn btn-primary">⏱ +30d</a>
                {action_btn}
                <a href="/action/delete/{u}" class="btn btn-dark" onclick="return confirm('¿Eliminar usuario?')">🗑 Eliminar</a>
            </div>
        </div>
        """

    # HTML GIGANTE
    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>GOLBERT PANEL PRO</title>
        <style>
            body {{ background-color: #0a0e17; color: #ffffff; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 15px; }}
            .header-top {{ display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }}
            .logo-title {{ font-size: 20px; font-weight: bold; color: #4facfe; display: flex; align-items: center; gap: 10px; }}
            .logo-title span {{ font-size: 12px; color: #8c9baf; font-weight: normal; display: block; }}
            
            .dashboard-grid {{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin-bottom: 20px; }}
            .stat-box {{ background: #131b2f; padding: 15px 10px; border-radius: 12px; text-align: center; border: 1px solid #1f2d4a; }}
            .stat-box h4 {{ margin: 0; font-size: 12px; color: #8c9baf; }}
            .stat-box h2 {{ margin: 5px 0 0 0; font-size: 22px; }}
            
            .btn-create {{ background: linear-gradient(135deg, #0061ff 0%, #60efff 100%); color: white; padding: 15px; border-radius: 12px; text-align: center; text-decoration: none; display: block; font-weight: bold; margin-bottom: 25px; box-shadow: 0 4px 15px rgba(0, 97, 255, 0.4); }}
            
            .section-title {{ font-size: 18px; margin-bottom: 15px; border-bottom: 1px solid #1f2d4a; padding-bottom: 10px; }}
            
            .user-card {{ background: #131b2f; border-radius: 15px; padding: 20px; margin-bottom: 15px; border: 1px solid #1f2d4a; box-shadow: 0 4px 10px rgba(0,0,0,0.2); }}
            .user-header {{ display: flex; justify-content: space-between; align-items: center; margin-bottom: 5px; }}
            .user-header h2 {{ margin: 0; font-size: 20px; }}
            .badge {{ font-weight: bold; font-size: 13px; }}
            .user-card p {{ margin: 5px 0; font-size: 14px; color: #d0d7e1; }}
            
            .card-actions {{ display: flex; gap: 8px; margin-top: 20px; }}
            .btn {{ flex: 1; text-align: center; padding: 10px 5px; border-radius: 8px; text-decoration: none; font-size: 13px; font-weight: bold; color: white; }}
            .btn-primary {{ background: #0047b3; }}
            .btn-danger {{ background: #900a22; }}
            .btn-warning {{ background: #b07d00; }}
            .btn-dark {{ background: #2c313c; }}
        </style>
    </head>
    <body>
        <div class="header-top">
            <div class="logo-title">
                🛡️ GOLBERT PANEL
                <span>Gestión de usuarios SSH / VPN</span>
            </div>
        </div>

        <div class="dashboard-grid">
            <div class="stat-box" style="border-top: 3px solid #28a745;">
                <h4>🟢 En línea</h4>
                <h2>{online_count}</h2>
            </div>
            <div class="stat-box" style="border-top: 3px solid #fd7e14;">
                <h4>⏳ Expirados</h4>
                <h2>{expirados_count}</h2>
            </div>
            <div class="stat-box" style="border-top: 3px solid #dc3545;">
                <h4>🚫 Bloqueados</h4>
                <h2>{blocked_count}</h2>
            </div>
        </div>

        <div class="section-title">Usuarios ({total_users})</div>
        
        {user_cards if user_cards else '<p style="text-align:center; color:#8c9baf;">No hay usuarios creados.</p>'}

    </body>
    </html>
    """
    return html

@app.route('/action/<cmd>/<user>')
@requires_auth
def action(cmd, user):
    # Validar que el usuario existe para evitar inyecciones
    if not subprocess.getoutput(f"id -u {user} 2>/dev/null"):
        return redirect(url_for('index'))
        
    if cmd == "lock":
        subprocess.getoutput(f"usermod -L {user}")
        subprocess.getoutput(f"pkill -u {user}")
    elif cmd == "unlock":
        subprocess.getoutput(f"usermod -U {user}")
    elif cmd == "delete":
        subprocess.getoutput(f"userdel -f {user}")
        subprocess.getoutput(f"rm -f /etc/vps-manager/banner_{user}.net")
        subprocess.getoutput(f"sed -i '/Match User {user}/,+1d' /etc/ssh/sshd_config")
        subprocess.getoutput("systemctl restart ssh")
    elif cmd == "renew":
        subprocess.getoutput(f"chage -E $(date -d '+30 days' +'%Y-%m-%d') {user}")
        
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8181)
EOF

# Inyectar credenciales reales en el código Python
sed -i "s/REPLACE_USER/$WEB_USER/g" "$WEB_DIR/app.py"
sed -i "s/REPLACE_PASS/$WEB_PASS/g" "$WEB_DIR/app.py"

# Abrir el puerto 8181 en el firewall
iptables -I INPUT -p tcp --dport 8181 -j ACCEPT
iptables-save > /etc/iptables.up.rules 2>/dev/null

# Crear servicio Systemd
cat << EOF > /etc/systemd/system/vps-webpanel.service
[Unit]
Description=Golbert VPS Web Panel PRO
After=network.target

[Service]
User=root
WorkingDirectory=$WEB_DIR
ExecStart=$WEB_DIR/venv/bin/python $WEB_DIR/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vps-webpanel >/dev/null 2>&1
systemctl restart vps-webpanel

IP_VPS=$(curl -s ipv4.icanhazip.com)
clear
echo -e "${C_GREEN}[✔] ¡Panel Web PRO Instalado y Activo!${C_NC}"
echo -e "${C_CYAN}================================================${C_NC}"
echo -e " 🌐 URL del Panel : ${C_YELLOW}http://$IP_VPS:8181${C_NC}"
echo -e " 👤 Usuario       : $WEB_USER"
echo -e " 🔑 Contraseña    : $WEB_PASS"
echo -e "${C_CYAN}================================================${C_NC}"
read -p "Presione Enter para regresar..."
