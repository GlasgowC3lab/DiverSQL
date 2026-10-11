#!/usr/bin/env python3
"""
Sidecar metrics scraper with a tiny HTTP control server.

- Runs an HTTP server (default :8099) with:
  POST /start  {"out_path": "..."}   or {"out_dir": "...", "filename": "..."}
  POST /stop   {}
  GET  /status

- When started, scrapes local endpoints (default 127.0.0.1 ports) at PERIOD_MS cadence,
  writes a wide CSV, and stops on /stop.

Notes:
- Designed for a sidecar container in the same Pod as Trino => localhost works.
- Only ONE active scrape job per sidecar instance.
"""

import os
import time
import json
import http.client
import threading
import logging
from typing import Optional, Tuple, List, Dict, Any
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse


# -----------------------
# Metrics
# -----------------------

# CPU
PROCESS_CPU = ("process_cpu_seconds_total", 7071)
NODE_CPU = ("node_cpu_seconds_total", 9100)

# Memory
TRINO_MEM = ("trino_memory_bytes_total", 9102)

# Disk
TRINO_READ = ("io_trino_plugin_base_metrics_FileFormatDataSourceStats_ReadBytes_AllTime_Total_total", 7071)

# Network
HTTP_SENT = ("io_airlift_http_server_HttpServer_HttpConnectionStats_SentBytes_total", 7071)
HTTP_RECV = ("io_airlift_http_server_HttpServer_HttpConnectionStats_ReceivedBytes_total", 7071)


CSV_HEADER = (
    "epoch_ms,process_cpu_s,node_cpu_idle_s,trino_mem_bytes,"
    "trino_read_bytes,http_sent_bytes,http_recv_bytes\n"
)


# -----------------------
# Logging
# -----------------------
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO").upper(),
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger("metrics-sidecar")


# Local endpoints inside pod netns
SCRAPE_HOST = "127.0.0.1"

# Control server
CONTROL_HOST = os.getenv("CONTROL_HOST", "0.0.0.0")
CONTROL_PORT = int(os.getenv("CONTROL_PORT", "8099"))


# -----------------------
# Cadence / IO settings
# -----------------------
# Keep these as plain module constants (no config style changes)
PERIOD_MS = 200          # fast scrape cadence
NODE_PERIOD_MS = 200    # node exporter is heavy; cache it

FAST_TIMEOUT_S = 1
MEM_TIMEOUT_S = 1
NODE_TIMEOUT_S = 1.0

FLUSH_LINES = 10

DEFAULT_OUT_DIR = "/data"
DEFAULT_FILENAME = "metrics.csv"


# -----------------------
# Derived names/ports from your tuples (still your tuple style)
# -----------------------
M_PROCESS_CPU, FAST_PORT = PROCESS_CPU
M_NODE_CPU, NODE_PORT = NODE_CPU
M_TRINO_MEM, MEM_PORT = TRINO_MEM
M_TRINO_READ, _ = TRINO_READ
M_HTTP_SENT, _ = HTTP_SENT
M_HTTP_RECV, _ = HTTP_RECV


# -----------------------
# HTTP keep-alive client
# -----------------------
class KeepAliveClient:
    def __init__(self, host: str, port: int, timeout_s: float):
        self.host = host
        self.port = port
        self.timeout_s = timeout_s
        self._conn: Optional[http.client.HTTPConnection] = None

    def _ensure_conn(self) -> http.client.HTTPConnection:
        if self._conn is None:
            self._conn = http.client.HTTPConnection(self.host, self.port, timeout=self.timeout_s)
        return self._conn

    def get(self, path: str = "/metrics") -> Optional[bytes]:
        conn = self._ensure_conn()
        try:
            conn.request(
                "GET",
                path,
                headers={
                    "Host": f"{self.host}:{self.port}",
                    "Connection": "keep-alive",
                    "Accept": "text/plain",
                },
            )
            resp = conn.getresponse()
            try:
                if resp.status != 200:
                    _ = resp.read()
                    return None
                return resp.read()
            finally:
                # IMPORTANT: allow connection reuse
                resp.close()
        except Exception as e:
            log.debug(f"{self.host}:{self.port} request failed: {e}")
            try:
                if self._conn is not None:
                    self._conn.close()
            except Exception:
                pass
            self._conn = None
            return None

    def get_with_retry(self, path: str = "/metrics") -> Optional[bytes]:
        data = self.get(path)
        if data is not None:
            return data
        # force reconnect and retry once
        try:
            if self._conn is not None:
                self._conn.close()
        except Exception:
            pass
        self._conn = None
        return self.get(path)


# -----------------------
# Parsing helpers (FAST: byte-scanning, no full decode per scrape)
# -----------------------
def _value_token_b(line: bytes) -> bytes:
    i = line.find(b" ")
    if i == -1:
        return b"NaN"
    j = i
    n = len(line)
    while j < n and line[j:j + 1] == b" ":
        j += 1
    if j >= n:
        return b"NaN"
    k = line.find(b" ", j)
    if k == -1:
        return line[j:]
    return line[j:k]

def _is_metric_line_b(line: bytes, name_b: bytes) -> bool:
    return line.startswith(name_b + b"{") or line.startswith(name_b + b" ")

def parse_fast_metrics(body: bytes) -> Tuple[str, str, str, str]:
    pc = rb = sb = rcv = b"NaN"

    m_pc = M_PROCESS_CPU.encode("ascii", "ignore")
    m_rb = M_TRINO_READ.encode("ascii", "ignore")
    m_sb = M_HTTP_SENT.encode("ascii", "ignore")
    m_rcv = M_HTTP_RECV.encode("ascii", "ignore")

    for line in body.split(b"\n"):
        if not line or line[:1] == b"#":
            continue

        if pc == b"NaN" and _is_metric_line_b(line, m_pc):
            pc = _value_token_b(line)
        elif rb == b"NaN" and _is_metric_line_b(line, m_rb):
            rb = _value_token_b(line)
        elif sb == b"NaN" and _is_metric_line_b(line, m_sb):
            sb = _value_token_b(line)
        elif rcv == b"NaN" and _is_metric_line_b(line, m_rcv):
            rcv = _value_token_b(line)

        if pc != b"NaN" and rb != b"NaN" and sb != b"NaN" and rcv != b"NaN":
            break

    return (
        pc.decode("ascii", "ignore"),
        rb.decode("ascii", "ignore"),
        sb.decode("ascii", "ignore"),
        rcv.decode("ascii", "ignore"),
    )

def parse_single_metric(body: bytes, metric_name: str) -> str:
    name_b = metric_name.encode("ascii", "ignore")
    for line in body.split(b"\n"):
        if not line or line[:1] == b"#":
            continue
        if _is_metric_line_b(line, name_b):
            return _value_token_b(line).decode("ascii", "ignore")
    return "NaN"

def parse_node_idle_sum(body: bytes) -> str:
    s = 0.0
    found = False

    prefix = (M_NODE_CPU + "{").encode("ascii", "ignore")
    needle = b'mode="idle"'

    for line in body.split(b"\n"):
        if not line or line[:1] == b"#":
            continue
        if not line.startswith(prefix):
            continue
        if needle not in line:
            continue
        val = _value_token_b(line)
        try:
            s += float(val)
            found = True
        except Exception:
            pass

    return f"{s}" if found else "NaN"


# -----------------------
# Scraper job state
# -----------------------
class ScrapeJob:
    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.thread: Optional[threading.Thread] = None
        self.stop_event: Optional[threading.Event] = None

        self.running: bool = False
        self.out_path: Optional[str] = None

        # counters
        self.tick: int = 0
        self.fast_failures: int = 0
        self.mem_failures: int = 0
        self.node_failures: int = 0
        self.last_epoch_ms: Optional[int] = None
        self.started_at_epoch_ms: Optional[int] = None

    def status(self) -> Dict[str, Any]:
        with self.lock:
            return {
                "running": self.running,
                "out_path": self.out_path,
                "tick": self.tick,
                "fast_failures": self.fast_failures,
                "mem_failures": self.mem_failures,
                "node_failures": self.node_failures,
                "started_at_epoch_ms": self.started_at_epoch_ms,
                "last_epoch_ms": self.last_epoch_ms,
                "period_ms": PERIOD_MS,
                "node_period_ms": NODE_PERIOD_MS,
                "endpoints": {
                    "fast": f"http://{SCRAPE_HOST}:{FAST_PORT}/metrics",
                    "mem": f"http://{SCRAPE_HOST}:{MEM_PORT}/metrics",
                    "node": f"http://{SCRAPE_HOST}:{NODE_PORT}/metrics",
                },
            }

JOB = ScrapeJob()


# -----------------------
# Scrape loop (runs in background thread)
# -----------------------
def scrape_loop(out_path: str, stop_event: threading.Event) -> None:
    os.makedirs(os.path.dirname(out_path), exist_ok=True)

    new_file = not os.path.exists(out_path)
    if new_file:
        with open(out_path, "w", encoding="utf-8") as wf:
            wf.write(CSV_HEADER)

    fast = KeepAliveClient(SCRAPE_HOST, FAST_PORT, FAST_TIMEOUT_S)
    mem = KeepAliveClient(SCRAPE_HOST, MEM_PORT, MEM_TIMEOUT_S)
    node = KeepAliveClient(SCRAPE_HOST, NODE_PORT, NODE_TIMEOUT_S)

    node_idle_cache = "NaN"
    next_node_deadline = time.monotonic_ns() + NODE_PERIOD_MS * 1_000_000

    buf: List[str] = []
    buf_count = 0

    period_ns = PERIOD_MS * 1_000_000
    next_deadline = time.monotonic_ns() + period_ns

    log.info(f"Scrape started -> {out_path}")

    f = open(out_path, "a", encoding="utf-8")
    try:
        while not stop_event.is_set():
            epoch_ms = time.time_ns() // 1_000_000
            # update shared state
            with JOB.lock:
                JOB.tick += 1
                JOB.last_epoch_ms = epoch_ms

            # node cache (heavy)
            now_ns = time.monotonic_ns()
            if now_ns >= next_node_deadline:
                next_node_deadline = now_ns + NODE_PERIOD_MS * 1_000_000
                nb = node.get_with_retry("/metrics")
                if nb:
                    node_idle_cache = parse_node_idle_sum(nb)
                else:
                    with JOB.lock:
                        JOB.node_failures += 1
                    node_idle_cache = "NaN"

            # fast scrape (7071)
            fb = fast.get_with_retry("/metrics")
            if fb:
                pc, rb, sb, rcv = parse_fast_metrics(fb)
            else:
                with JOB.lock:
                    JOB.fast_failures += 1
                pc, rb, sb, rcv = ("NaN", "NaN", "NaN", "NaN")

            # mem scrape (9102)
            mb = mem.get_with_retry("/metrics")
            if mb:
                trino_mem = parse_single_metric(mb, M_TRINO_MEM)
            else:
                with JOB.lock:
                    JOB.mem_failures += 1
                trino_mem = "NaN"

            buf.append(f"{epoch_ms},{pc},{node_idle_cache},{trino_mem},{rb},{sb},{rcv}\n")
            buf_count += 1

            if buf_count >= FLUSH_LINES:
                f.writelines(buf)
                f.flush()
                buf.clear()
                buf_count = 0

            # stable cadence sleep
            now_ns = time.monotonic_ns()
            sleep_ns = next_deadline - now_ns
            if sleep_ns > 0:
                time.sleep(sleep_ns / 1_000_000_000)
                next_deadline += period_ns
            else:
                next_deadline = time.monotonic_ns() + period_ns
    except Exception as e:
        print(e)
    finally:
        if buf:
            f.writelines(buf)
        try:
            f.flush()
        finally:
            f.close()
        log.info(f"Scrape stopped -> {out_path}")


# -----------------------
# Control server helpers
# -----------------------
def _read_json(handler: BaseHTTPRequestHandler) -> Dict[str, Any]:
    length = int(handler.headers.get("Content-Length", "0") or "0")
    if length <= 0:
        return {}
    raw = handler.rfile.read(length)
    if not raw:
        return {}
    try:
        return json.loads(raw.decode("utf-8"))
    except Exception:
        return {}

def _send_json(handler: BaseHTTPRequestHandler, code: int, obj: Dict[str, Any]) -> None:
    data = json.dumps(obj).encode("utf-8")
    handler.send_response(code)
    handler.send_header("Content-Type", "application/json")
    handler.send_header("Content-Length", str(len(data)))
    handler.end_headers()
    handler.wfile.write(data)

def start_job(out_path: str) -> Tuple[bool, str]:
    with JOB.lock:
        if JOB.running:
            return False, f"already running (out_path={JOB.out_path})"

        stop_event = threading.Event()
        t = threading.Thread(
            target=scrape_loop,
            args=(out_path, stop_event),
            name="scrape-loop",
            daemon=True,  # ok for sidecar; stop will flush anyway
        )

        JOB.stop_event = stop_event
        JOB.thread = t
        JOB.running = True
        JOB.out_path = out_path

        JOB.tick = 0
        JOB.fast_failures = 0
        JOB.mem_failures = 0
        JOB.node_failures = 0
        JOB.last_epoch_ms = None
        JOB.started_at_epoch_ms = time.time_ns() // 1_000_000

        t.start()
        return True, "started"

def stop_job() -> Tuple[bool, str]:
    with JOB.lock:
        if not JOB.running or JOB.stop_event is None or JOB.thread is None:
            return False, "not running"
        stop_event = JOB.stop_event
        thread = JOB.thread

    stop_event.set()
    thread.join(timeout=10)

    with JOB.lock:
        JOB.running = False
        JOB.stop_event = None
        JOB.thread = None

    return True, "stopped"

def resolve_out_path(payload: Dict[str, Any]) -> str:
    # precedence:
    # 1) explicit out_path
    # 2) out_dir + filename
    # 3) defaults
    out_path = payload.get("out_path")
    if isinstance(out_path, str) and out_path.strip():
        return out_path

    out_dir = payload.get("out_dir") or DEFAULT_OUT_DIR
    filename = payload.get("filename") or DEFAULT_FILENAME
    return os.path.join(str(out_dir), str(filename))


# -----------------------
# HTTP handler
# -----------------------
class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args: Any) -> None:
        # route http.server logs through logging module (less spammy)
        log.debug("%s - %s" % (self.address_string(), fmt % args))

    def do_GET(self) -> None:
        path = urlparse(self.path).path
        if path == "/status":
            _send_json(self, 200, {"ok": True, "status": JOB.status()})
            return
        _send_json(self, 404, {"ok": False, "error": "not found"})

    def do_POST(self) -> None:
        path = urlparse(self.path).path
        payload = _read_json(self)

        if path == "/start":
            out_path = resolve_out_path(payload)
            ok, msg = start_job(out_path)
            code = 200 if ok else 409
            _send_json(self, code, {"ok": ok, "message": msg, "status": JOB.status()})
            return

        if path == "/stop":
            ok, msg = stop_job()
            code = 200 if ok else 409
            _send_json(self, code, {"ok": ok, "message": msg, "status": JOB.status()})
            return

        _send_json(self, 404, {"ok": False, "error": "not found"})


# -----------------------
# Entrypoint
# -----------------------
def main() -> None:
    server = ThreadingHTTPServer((CONTROL_HOST, CONTROL_PORT), Handler)
    log.info(f"Control server listening on http://{CONTROL_HOST}:{CONTROL_PORT}")
    log.info("Endpoints: POST /start, POST /stop, GET /status")
    server.serve_forever()

if __name__ == "__main__":
    main()
