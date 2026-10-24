#!/usr/bin/env python3
import socket
import threading
import select
import sys

LISTENING_ADDR = '0.0.0.0'
LISTENING_PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 80
DEFAULT_HOST = '127.0.0.1:22'
BUFLEN = 4096 * 4
TIMEOUT = 60

class ClientThread(threading.Thread):
    def __init__(self, client_socket):
        threading.Thread.__init__(self)
        self.client = client_socket
        self.target = None

    def run(self):
        try:
            payload = self.client.recv(BUFLEN).decode('utf-8', errors='ignore')
            if not payload:
                self.client.close()
                return

            host, port = DEFAULT_HOST.split(':')
            self.target = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.target.connect((host, int(port)))

            # Detección inteligente para E-Proxy, HTTP Proxy y WebSockets
            if 'upgrade: websocket' in payload.lower():
                response = (
                    "HTTP/1.1 101 Switching Protocols\r\n"
                    "Upgrade: websocket\r\n"
                    "Connection: Upgrade\r\n\r\n"
                )
            elif 'HTTP/' in payload:
                response = (
                    "HTTP/1.1 200 Connection established\r\n"
                    "Proxy-Agent: GolbertVPS-EProxy\r\n"
                    "Connection: keep-alive\r\n\r\n"
                )
            else:
                response = b""

            if response:
                self.client.sendall(response.encode('utf-8'))
            
            self.forward_traffic()

        except Exception:
            pass
        finally:
            if self.client:
                self.client.close()
            if self.target:
                self.target.close()

    def forward_traffic(self):
        sockets = [self.client, self.target]
        while True:
            r, _, e = select.select(sockets, [], sockets, TIMEOUT)
            if e or not r:
                break
            for sock in r:
                data = sock.recv(BUFLEN)
                if not data:
                    return
                if sock is self.client:
                    self.target.sendall(data)
                else:
                    self.client.sendall(data)

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((LISTENING_ADDR, LISTENING_PORT))
    server.listen(128)
    print(f"[*] Proxy E-Proxy / HTTP activo en el puerto {LISTENING_PORT}")

    while True:
        try:
            client_sock, _ = server.accept()
            handler = ClientThread(client_sock)
            handler.daemon = True
            handler.start()
        except KeyboardInterrupt:
            break

if __name__ == '__main__':
    main()
    
