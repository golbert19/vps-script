import socket
import threading

def handle_client(client_socket):
    try:
        request = client_socket.recv(2048)
        if not request:
            client_socket.close()
            return

        # Conectar al SSH local
        ssh_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh_socket.connect(('127.0.0.1', 22))

        # Respuesta clásica de WebSocket que acepta tu payload
        response = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
        client_socket.sendall(response.encode('utf-8'))

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
    server.bind(('0.0.0.0', 80))
    # Cola grande (500) para soportar multiconexiones sin rechazos
    server.listen(500) 
    while True:
        try:
            client, addr = server.accept()
            # AQUÍ ESTABA EL ERROR: Ahora sí iniciamos el hilo (Thread) correctamente
            t = threading.Thread(target=handle_client, args=(client,))
            t.daemon = True
            t.start()
        except:
            continue

if __name__ == '__main__':
    main()
    
