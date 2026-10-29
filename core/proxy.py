import socket
import threading
import sys
import subprocess

def get_user_expiration(username):
    try:
        cmd = f"chage -l {username} | grep 'Account expires'"
        output = subprocess.check_output(cmd, shell=True).decode('utf-8')
        return output.split(':')[1].strip()
    except:
        return "Ilimitado"

def handle_client(client_socket):
    try:
        request = client_socket.recv(2048).decode('utf-8', errors='ignore')
        if not request:
            client_socket.close()
            return

        # 1. Responder al protocolo WebSocket
        response = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
        client_socket.sendall(response.encode('utf-8'))

        # 2. Conectar al servicio SSH local (puerto 22)
        ssh_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh_socket.connect(('127.0.0.1', 22))

        # 3. Inyectar datos de banner formateados para que la app los capture en el log
        # (Aquí puedes ajustar el formato visual exacto que lee tu app)
        banner_info = (
            "\r\n"
            "========================================\r\n"
            "        GOLBERT VPS - CONEXIÓN          \r\n"
            "========================================\r\n"
            " Estado    : Conectado Exitosamente      \r\n"
            " Servidor  : Operativo                   \r\n"
            "========================================\r\n\r\n"
        )
        client_socket.sendall(banner_info.encode('utf-8'))

        # 4. Puente de transferencia bidireccional de datos
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

    except Exception:
        client_socket.close()

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', 80))
    server.listen(500)
    while True:
        try:
            client, addr = server.accept()
            threading.Thread(target=handle_client, args=(client,)).daemon = True
            client.start()
        except:
            continue

if __name__ == '__main__':
    main()
