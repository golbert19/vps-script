import socket
import threading
import sys
import os
import subprocess

def get_user_info(username):
    # Obtener fecha de expiración del usuario del sistema Linux
    try:
        cmd = f"chage -l {username} | grep 'Account expires'"
        output = subprocess.check_output(cmd, shell=True).decode('utf-8')
        # Ejemplo de salida: Account expires : Nov 03, 2026
        expiry_date = output.split(':')[1].strip()
        return expiry_date
    except:
        return "Ilimitado"

def handle_client(client_socket):
    try:
        request = client_socket.recv(2048).decode('utf-8', errors='ignore')
        if not request:
            client_socket.close()
            return

        # Responder al Payload WebSocket
        response = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
        client_socket.sendall(response.encode('utf-8'))

        # Conectar al servicio SSH local (puerto 22)
        ssh_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh_socket.connect(('127.0.0.1', 22))

        # Opcional: Enviar cabecera o mensaje informativo inicial de bienvenida al socket
        # (Esto es lo que algunas apps leen como detalles de cuenta)
        welcome_msg = "\n==============================\n" \
                      " Usuario: Activo en Golbert VPS \n" \
                      " Estado: Conexión Exitosa     \n" \
                      "==============================\n\n"
        client_socket.sendall(welcome_msg.encode('utf-8'))

        # Hilos concurrentes de transferencia
        t1 = threading.Thread(target=transfer, args=(client_socket, ssh_socket))
        t2 = threading.Thread(target=transfer, args=(ssh_socket, client_socket))
        t1.daemon = True
        t2.daemon = True
        t1.start()
        t2.start()
    except Exception:
        client_socket.close()

def transfer(src, dst):
    try:
        while True:
            data = src.recv(8192)
            if not data: break
            dst.sendall(data)
    except Exception:
        pass
    finally:
        try: src.close()
        except: pass
        try: dst.close()
        except: pass

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', 80))
    server.listen(500)
    print("Proxy WebSocket con inyección de estado escuchando en puerto 80...")
    while True:
        try:
            client, addr = server.accept()
            threading.Thread(target=handle_client, args=(client,)).daemon = True
            client.start() if hasattr(client, 'start') else None
        except Exception:
            continue

if __name__ == '__main__':
    main()
    
