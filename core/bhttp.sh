#!/bin/bash
# ==========================================
# Instalador BHTTP Proxy - Autónomo
# ==========================================
C_ORANGE='\033[38;5;214m'; C_BLUE='\033[1;34m'; C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_RED='\033[1;31m'; C_NC='\033[0m'
DEFAULT_PORT=8180

clear
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
echo -e "               ${C_BLUE}INSTALACIÓN DE BHTTP${C_NC}"
echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
mkdir -p /etc/vps-manager/bhttp
systemctl stop bhttp > /dev/null 2>&1

while true; do
    read -p "$(echo -e "${C_ORANGE}Puerto de escucha (--port) [Default $DEFAULT_PORT]: ${C_NC}")" INPUT_PORT
    FINAL_PORT=${INPUT_PORT:-$DEFAULT_PORT}
    if ! [[ "$FINAL_PORT" =~ ^[0-9]+$ ]]; then echo -e " ${C_RED}[!] Número inválido.${C_NC}"; continue; fi
    if netstat -tuln | grep -qE ":$FINAL_PORT\b"; then echo -e " ${C_RED}[!] Puerto en uso.${C_NC}"; else break; fi
done

echo -e "\n${C_GREEN}[OK] Construyendo motor BHTTP en el puerto $FINAL_PORT...${C_NC}"

# Incrustamos el script Python completo para evitar errores 404 de GitHub
cat << 'EOF' > /etc/vps-manager/bhttp/BHTTP.py
#!/usr/bin/env python3
import socket, struct, hashlib, threading, json, time, logging, ipaddress, select, os, ssl, traceback, sys
from dataclasses import dataclass, field
from typing import Optional, Dict, Tuple

CONFIG = {
    "server": {"virtual_subnet_cidr": "10.10.0.0/16"},
    "proxy": {"listen": [{"host": "0.0.0.0", "port": 80, "ssl": False}], "target": {"host": "127.0.0.1", "port": 22}},
    "tls": {"certificate": "/etc/ssl/certs/bhttp.crt", "private_key": "/etc/ssl/private/bhttp.key"},
}

logging.basicConfig(format="%(asctime)s %(levelname)s [%(name)s] %(message)s", datefmt="%Y-%m-%d %H:%M:%S", level=logging.DEBUG)
log = logging.getLogger("BHTTP")

MODE_PROBE, MODE_UPLOAD, MODE_DOWNLOAD, MODE_BATCH, MODE_ACK = 0, 1, 2, 3, 4
STATUS_OK, STATUS_DATA = 0, 2
HEADER_SIZE = 29
SESSIONS_LOCK = threading.Lock()
PKT_AUTH, PKT_DATA, PKT_KEEPALIVE, PKT_DISCONNECT, PKT_IP = 1, 2, 3, 4, 5

def bhttp_crypt(data: bytes, sid: bytes, mode: int, seq: int, isr: bool) -> bytes:
    if not data: return b""
    out, sb = bytearray(len(data)), bytearray(26)
    sb[0:16] = sid[:16]
    sb[16] = mode & 0xFF
    struct.pack_into(">Q", sb, 17, seq)
    sb[25] = 1 if isr else 0
    o = i = 0
    while o < len(data):
        k = hashlib.sha256(bytes(sb) + struct.pack(">I", i)).digest()
        n = min(32, len(data) - o)
        for j in range(n): out[o + j] = data[o + j] ^ k[j]
        o += n; i += 1
    return bytes(out)

def encode_packet(pkt_type: int, stream_id: int, payload: bytes) -> bytes:
    return struct.pack(">BII", pkt_type, stream_id, len(payload)) + payload

def decode_packet(data: bytes) -> Tuple[int, int, bytes]:
    if len(data) < 9: raise ValueError(f"Packet too short: {len(data)} bytes")
    pkt_type, stream_id, plen = struct.unpack_from(">BII", data, 0)
    return pkt_type, stream_id, data[9:9 + plen]

class IPPool:
    def __init__(self, cidr: str):
        self.network = ipaddress.ip_network(cidr, strict=False)
        self.hosts = iter(self.network.hosts())
        next(self.hosts)
        self.assigned: Dict[str, str] = {}
        self.lock = threading.Lock()
    def assign(self, sid_hex: str) -> Optional[str]:
        with self.lock:
            if sid_hex in self.assigned: return self.assigned[sid_hex]
            try:
                ip = str(next(self.hosts))
                self.assigned[sid_hex] = ip
                return ip
            except StopIteration: return None
    def release(self, sid_hex: str):
        with self.lock: self.assigned.pop(sid_hex, None)
    @property
    def subnet_mask(self) -> str: return str(self.network.netmask)
    @property
    def gateway(self) -> str: return str(next(self.network.hosts()))

@dataclass
class Session:
    sid: bytes
    target: Optional[socket.socket] = None
    target_started: bool = False
    target_eof: bool = False
    target_error: str = ""
    banner_delivered: bool = False
    download_buffer: bytearray = field(default_factory=bytearray)
    upload_pending: Dict[int, bytes] = field(default_factory=dict)
    upload_next_seq: int = 0
    first_upload_logged: bool = False
    lock: threading.RLock = field(default_factory=threading.RLock)
    download_next_seq: int = 0
    download_acked_seq: int = -1
    download_closed: bool = False
    download_frames: Dict[int, bytes] = field(default_factory=dict)
    download_order_lock: threading.Lock = field(default_factory=threading.Lock)
    download_order: threading.Condition = field(init=False)
    ready: threading.Condition = field(init=False)
    last_seen: float = field(default_factory=time.time)

    def __post_init__(self):
        self.ready = threading.Condition(self.lock)
        self.download_order = threading.Condition(self.download_order_lock)

    def acknowledge_download(self, seq: int):
        with self.download_order:
            if seq <= self.download_acked_seq: return
            self.download_acked_seq = seq
            stale = [number for number in self.download_frames if number <= seq]
            for number in stale: self.download_frames.pop(number, None)

    def open_target(self, host: str, port: int) -> bool:
        with self.lock:
            if self.target is not None: return True
            if self.target_started: return not self.target_error
            self.target_started = True
        try:
            target = socket.create_connection((host, port), timeout=10)
            target.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            target.settimeout(None)
        except OSError as exc:
            with self.ready:
                self.target_error = str(exc)
                self.target_eof = True
                self.ready.notify_all()
            return False
        with self.ready:
            self.target = target
            self.ready.notify_all()
        threading.Thread(target=self._read_target, daemon=True).start()
        return True

    def _read_target(self):
        tag = self.sid.hex()[:8]
        try:
            while True:
                data = self.target.recv(65536) if self.target else b""
                if not data: break
                with self.ready:
                    self.download_buffer.extend(data)
                    self.last_seen = time.time()
                    self.ready.notify_all()
        except OSError as exc:
            with self.lock:
                if not self.target_error: self.target_error = str(exc)
        finally:
            with self.ready:
                self.target_eof = True
                self.ready.notify_all()
            with self.download_order:
                self.download_closed = True
                self.download_order.notify_all()

    def write_upload(self, seq: int, payload: bytes):
        with self.lock:
            if seq < self.upload_next_seq: return
            self.upload_pending.setdefault(seq, payload)
            while self.upload_next_seq in self.upload_pending:
                chunk = self.upload_pending.pop(self.upload_next_seq)
                if not self.first_upload_logged and chunk: self.first_upload_logged = True
                if chunk and self.target is not None: self.target.sendall(chunk)
                self.upload_next_seq += 1
                self.last_seen = time.time()

    def take_download(self, seq: int, size: int, banner_timeout: float = 5.0) -> bytes:
        size = min(max(size, 1), 524284)
        deadline = time.monotonic() + banner_timeout
        with self.ready:
            if not self.banner_delivered and seq != 0: return b""
            while not self.download_buffer and not self.target_eof:
                if self.banner_delivered or deadline - time.monotonic() <= 0: return b""
                self.ready.wait(deadline - time.monotonic())
            if not self.download_buffer: return b""
            chunk = bytes(self.download_buffer[:size])
            del self.download_buffer[:len(chunk)]
            if not self.banner_delivered: self.banner_delivered = True
            self.last_seen = time.time()
            return chunk

    def close(self):
        with self.ready:
            target = self.target
            self.target = None
            self.target_eof = True
            self.ready.notify_all()
        with self.download_order:
            self.download_closed = True
            self.download_order.notify_all()
        if target:
            try: target.close()
            except OSError: pass

def auth_dict(username: str, password: str) -> bool: return CONFIG.get("users", {}).get(username) == password
def auth_system(username: str, password: str) -> bool:
    try:
        import pam
        p = pam.pam()
        return p.authenticate(username, password)
    except ImportError: return auth_dict(username, password)
def authenticate(username: str, password: str) -> bool:
    if CONFIG["server"].get("auth", {}).get("system"): return auth_system(username, password)
    return auth_dict(username, password)

def read_bhttp_frame_buf(sock: socket.socket, buf: bytes) -> Tuple[int, bytes, int, bytes, bytes]:
    while len(buf) < HEADER_SIZE:
        chunk = sock.recv(4096)
        if not chunk: raise ConnectionError("Connection closed")
        buf += chunk
    header, buf = buf[:HEADER_SIZE], buf[HEADER_SIZE:]
    mode, sid = header[0], header[1:17]
    seq = struct.unpack(">Q", header[17:25])[0]
    length = struct.unpack(">I", header[25:29])[0]
    if mode in (MODE_DOWNLOAD, MODE_ACK): return mode, sid, seq, b"", buf
    while len(buf) < length:
        chunk = sock.recv(max(4096, length - len(buf)))
        if not chunk: raise ConnectionError("Connection closed")
        buf += chunk
    return mode, sid, seq, buf[:length], buf[length:]

def send_bhttp_status(sock: socket.socket, status: int, data: bytes = b""):
    sock.sendall(struct.pack(">BI", status, len(data)) + data)

def send_bhttp_download(sock: socket.socket, sid: bytes, data: bytes, mode: int = MODE_DOWNLOAD, seq: int = 0):
    enc = bhttp_crypt(data, sid, mode, seq, True)
    payload = struct.pack(">I", len(data)) + enc
    sock.sendall(struct.pack(">BI", STATUS_DATA, len(payload)) + payload)

def handle_bhttp_probe(conn: socket.socket):
    mode, sid, seq, encrypted, _ = read_bhttp_frame_buf(conn, b"")
    clear = bhttp_crypt(encrypted, sid, MODE_PROBE, seq, False)
    if len(clear) < 10 or clear[:4] != b"BHP1" or clear[4] != 1: return
    submode = clear[5]
    parameter = struct.unpack_from(">I", clear, 6)[0]
    response_size = max(parameter, 10) if submode == MODE_DOWNLOAD else 10
    response = bytearray(response_size)
    response[:4] = b"BHP1"
    response[4] = 1; response[5] = submode
    struct.pack_into(">I", response, 6, parameter)
    for index in range(10, response_size): response[index] = (index * 31) & 0xFF
    encrypted_response = bhttp_crypt(bytes(response), sid, MODE_PROBE, seq, True)
    response_count = min(max(parameter, 1), 256) if submode == MODE_ACK else 1
    for _ in range(response_count): send_bhttp_status(conn, STATUS_OK, encrypted_response)

class SessionHandler:
    def __init__(self, conn: socket.socket, addr, sessions: dict, ip_pool: IPPool, extra_bytes: bytes = b""):
        self.conn, self.addr, self.sessions, self.ip_pool, self.extra_bytes = conn, addr, sessions, ip_pool, extra_bytes

    def get_session(self, sid: bytes) -> Session:
        sid_hex = sid.hex()
        with SESSIONS_LOCK:
            if sid_hex not in self.sessions: self.sessions[sid_hex] = Session(sid=sid)
            return self.sessions[sid_hex]

    def handle(self):
        try:
            while True:
                mode, sid, seq, enc_payload, self.extra_bytes = read_bhttp_frame_buf(self.conn, self.extra_bytes)
                session = self.get_session(sid)
                session.last_seen = time.time()
                payload = bhttp_crypt(enc_payload, sid, mode, seq, False) if enc_payload and mode == MODE_UPLOAD else b""

                if mode == MODE_UPLOAD:
                    with session.lock: self._handle_upload(session, seq, payload)
                elif mode == MODE_DOWNLOAD:
                    with session.download_order:
                        while seq > session.download_next_seq and not session.download_closed: session.download_order.wait()
                        if seq == session.download_next_seq:
                            chunk = session.take_download(seq, 65536)
                            if chunk: session.download_frames[seq] = chunk
                            session.download_next_seq += 1
                            session.download_order.notify_all()
                        else: chunk = session.download_frames.get(seq, b"")
                        send_bhttp_download(self.conn, session.sid, chunk, mode, seq)
                elif mode == MODE_ACK:
                    session.acknowledge_download(seq)
                    send_bhttp_status(self.conn, STATUS_OK)
        except: pass
        finally: self.conn.close()

    def _handle_upload(self, session: Session, seq: int, payload: bytes):
        if seq == 0 and not payload:
            target = CONFIG["proxy"]["target"]
            if session.open_target(target["host"], target["port"]): send_bhttp_status(self.conn, STATUS_OK)
            else: send_bhttp_status(self.conn, 1, b"SSH target unavailable")
            return
        if session.target is None:
            target = CONFIG["proxy"]["target"]
            if not session.open_target(target["host"], target["port"]):
                send_bhttp_status(self.conn, 1, b"SSH target unavailable")
                return
        try:
            session.write_upload(seq, payload)
            send_bhttp_status(self.conn, STATUS_OK)
        except: send_bhttp_status(self.conn, 1, b"SSH upload failed")

def handle_http_upgrade(conn: socket.socket) -> Tuple[bool, bytes]:
    try:
        buf = b""
        while b"\r\n\r\n" not in buf:
            chunk = conn.recv(1024)
            if not chunk: return False, b""
            buf += chunk
    except: return False, b""
    idx = buf.find(b"\r\n\r\n") + 4
    conn.sendall(b"HTTP/1.1 101 BHTTP\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\nHTTP/1.1 200 BHTTP\r\n\r\n")
    return True, buf[idx:]

def handle_client(conn: socket.socket, addr, sessions: dict, ip_pool: IPPool):
    try:
        first = conn.recv(1, socket.MSG_PEEK)
        if not first:
            conn.close()
            return
        if first[0] == 0:
            handle_bhttp_probe(conn)
            conn.close()
            return
        extra_bytes = b""
        if first[0] not in (MODE_UPLOAD, MODE_DOWNLOAD, MODE_BATCH, MODE_ACK):
            success, extra_bytes = handle_http_upgrade(conn)
            if not success:
                conn.close()
                return
        SessionHandler(conn, addr, sessions, ip_pool, extra_bytes).handle()
    except: conn.close()

def start_listener(host: str, port: int, use_ssl: bool, sessions: dict, ip_pool: IPPool):
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind((host, port))
    srv.listen(128)
    while True:
        try:
            conn, addr = srv.accept()
            threading.Thread(target=handle_client, args=(conn, addr, sessions, ip_pool), daemon=True).start()
        except: pass

def cleanup_sessions(sessions: dict, ip_pool: IPPool, timeout: int = 120):
    while True:
        time.sleep(30)
        now = time.time()
        with SESSIONS_LOCK:
            dead = [k for k, s in sessions.items() if now - s.last_seen > timeout]
            for k in dead:
                session = sessions.pop(k, None)
                if session:
                    session.close()
                    ip_pool.release(k)

def main():
    if len(sys.argv) > 1 and sys.argv[1].isdigit():
        CONFIG["proxy"]["listen"][0]["port"] = int(sys.argv[1])
        
    ip_pool = IPPool(CONFIG["server"]["virtual_subnet_cidr"])
    sessions: Dict[str, Session] = {}
    threading.Thread(target=cleanup_sessions, args=(sessions, ip_pool), daemon=True).start()
    for lst in CONFIG["proxy"]["listen"]:
        threading.Thread(target=start_listener, args=(lst["host"], lst["port"], lst.get("ssl", False), sessions, ip_pool), daemon=True).start()
    try:
        while True: time.sleep(1)
    except KeyboardInterrupt: pass

if __name__ == "__main__":
    main()
EOF

cat << EOF > /etc/systemd/system/bhttp.service
[Unit]
Description=BHTTP Proxy Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/vps-manager/bhttp
ExecStart=/usr/bin/python3 /etc/vps-manager/bhttp/BHTTP.py $FINAL_PORT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bhttp >/dev/null 2>&1
systemctl restart bhttp
sleep 1

# -- Verificación Visual --
if systemctl is-active --quiet bhttp; then
    echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
    echo -e " ${C_GREEN}✅ BHTTP instalado y operando en el puerto $FINAL_PORT${C_NC}"
    echo -e "${C_ORANGE}------------------------------------------------------${C_NC}"
else
    echo -e "\n${C_RED}[!] Error crítico: El servicio BHTTP colapsó al iniciar.${C_NC}"
    echo -e "Registros de error:"
    journalctl -u bhttp -n 5 --no-pager
fi
read -p " Presiona Enter para volver..."
