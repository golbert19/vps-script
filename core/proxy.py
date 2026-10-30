import socket
import threading
import subprocess

# Función para consultar los días reales en Linux
def get_user_expiration(username):
    try:
        chage_out = subprocess.check_output(f"chage -l {username}", shell=True, stderr=subprocess.STDOUT).decode('utf-8')
        for line in chage_out.split('\n'):
            if "Account expires" in line or "La cuenta caduca" in line:
                date_str = line.split(':')[1].strip()
                return date_str if date_str != "never" else "Ilimitado"
        return "Desconocido"
    except:
        return "No encontrado"

def handle_client(client_socket):
    try:
        raw_request = client_socket.recv(4096)
        if not raw_request:
            client_socket.close()
            return

        request_text = raw_request.decode('utf-8', errors='ignore')
        request_lower = request_text.lower()

        # Buscar el usuario oculto en el Payload (Solo útil para WebSocket)
        ssh_user = None
        for line in request_text.split('\r\n'):
            if line.lower().startswith('x-user:') or line.lower().startswith('ssh-user:'):
                ssh_user = line.split(':')[1].strip()
                break

        # Conectar al daemon SSH local
        ssh_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh_socket.connect(('127.0.0.1', 22))

        # =======================================================
        # LÓGICA DUAL: Toma de decisión según el tipo de Payload
        # =======================================================
        
        if "upgrade: websocket" in request_lower:
            # 1. RESPUESTA WEBSOCKET (Con Banner Dinámico)
            response = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
            if ssh_user:
                exp_date = get_user_expiration(ssh_user)
                banner_html = (
                    f"<br><b><font color='#00FF00'>👤 Usuario : {ssh_user}</font></b><br>"
                    f"<b><font color='#FFFF00'>⏳ Expira  : {exp_date}</font></b><br>"
                    f"<b><font color='#00FFFF'>🛡️ Golbert VPS Premium</font></b><br><br>"
                )
                response += banner_html
        else:
            # 2. RESPUESTA DIRECTA CUSTOM (Engaño ISP / Bug Host)
            # Responde con la cabecera exacta que enviaste para asegurar la conexión
            response = "HTTP/2.0 1299\r\nHost: survey.tigo.com\nContent-Length: 55555555\n\r\n"

        # Enviar la respuesta decidida al cliente (HTTP Injector)
        client_socket.sendall(response.encode('utf-8'))

        # Función de túnel bidireccional
        def transfer(src, dst):
            try:
                while True:
                    data = src.recv(8192)
                    if not data: break
                    dst.sendall(data)
            except:
                pass
            finally:
                try: src.close()
                except: pass
                try: dst.close()
                except: pass

        t1 = threading.Thread(target=transfer, args=(client_socket, ssh_socket))
        t2 = threading.Thread(target=transfer, args=(ssh_socket, client_socket))
        t1.daemon = True
        t2.daemon = True
        t1.start()
        t2.start()
    except:
        try: client_socket.close()
        except: pass

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    # Configurado en el puerto 8080 (puedes cambiarlo a 442 si el 8080 está ocupado)
    server.bind(('0.0.0.0', 8080))
    server.listen(500) 
    print("Proxy Dual (WS + Direct Custom) iniciado en puerto 8080...")
    
    while True:
        try:
            client, addr = server.accept()
            t = threading.Thread(target=handle_client, args=(client,))
            t.daemon = True
            t.start()
        except:
            continue

if __name__ == '__main__':
    main()
    
