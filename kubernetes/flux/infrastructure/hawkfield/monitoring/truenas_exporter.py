#!/usr/bin/env python3
# TrueNAS API -> Prometheus exporter. Talks the 25.10 JSON-RPC WebSocket API
# (the REST API rejects non-admin keys). Stdlib only: a minimal WS client so the
# script can run from a stock python image mounted via ConfigMap.
import base64
import itertools
import json
import os
import socket
import ssl
import struct
import sys
import time
import traceback
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

NAS_HOST = os.environ.get("TRUENAS_HOST", "10.1.2.10")
NAS_PORT = int(os.environ.get("TRUENAS_PORT", "443"))
API_KEY = os.environ["TRUENAS_API_KEY"]
WS_PATH = os.environ.get("TRUENAS_WS_PATH", "/api/current")
LISTEN = int(os.environ.get("LISTEN_PORT", "9113"))


class WSError(Exception):
    pass


class WSClient:
    """Minimal RFC6453 client: TLS, text frames, client masking, reassembly."""

    def __init__(self, host, port, path, timeout=15):
        raw = socket.create_connection((host, port), timeout=timeout)
        ctx = ssl._create_unverified_context()  # noqa: S323 - TrueNAS serves a self-signed cert
        self.s = ctx.wrap_socket(raw, server_hostname=host)
        key = base64.b64encode(os.urandom(16)).decode()
        req = (
            f"GET {path} HTTP/1.1\r\nHost: {host}:{port}\r\n"
            "Upgrade: websocket\r\nConnection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n"
        )
        self.s.sendall(req.encode())
        resp = self._read_until(b"\r\n\r\n")
        if b" 101 " not in resp.split(b"\r\n", 1)[0]:
            raise WSError("ws upgrade failed: " + resp.split(b"\r\n", 1)[0].decode("latin1"))

    def _read_until(self, marker):
        buf = b""
        while marker not in buf:
            chunk = self.s.recv(4096)
            if not chunk:
                raise WSError("eof during handshake")
            buf += chunk
        return buf

    def _recv_exact(self, n):
        buf = b""
        while len(buf) < n:
            chunk = self.s.recv(n - len(buf))
            if not chunk:
                raise WSError("eof during frame")
            buf += chunk
        return buf

    def send(self, text):
        payload = text.encode()
        header = struct.pack("!B", 0x81)  # FIN + text
        mask = os.urandom(4)
        n = len(payload)
        if n < 126:
            header += struct.pack("!B", 0x80 | n)
        elif n < 65536:
            header += struct.pack("!BH", 0x80 | 126, n)
        else:
            header += struct.pack("!BQ", 0x80 | 127, n)
        masked = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
        self.s.sendall(header + mask + masked)

    def recv(self):
        data = b""
        while True:
            b0, b1 = self._recv_exact(2)
            fin = b0 & 0x80
            opcode = b0 & 0x0F
            ln = b1 & 0x7F
            if ln == 126:
                ln = struct.unpack("!H", self._recv_exact(2))[0]
            elif ln == 127:
                ln = struct.unpack("!Q", self._recv_exact(8))[0]
            payload = self._recv_exact(ln) if ln else b""
            if opcode == 0x9:  # ping -> pong
                self._send_control(0xA, payload)
                continue
            if opcode == 0x8:  # close
                raise WSError("server closed")
            data += payload
            if fin:
                return data

    def _send_control(self, opcode, payload):
        mask = os.urandom(4)
        masked = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
        self.s.sendall(struct.pack("!BB", 0x80 | opcode, 0x80 | len(payload)) + mask + masked)

    def close(self):
        try:
            self._send_control(0x8, b"")
            self.s.close()
        except OSError as e:
            sys.stderr.write(f"ws close failed: {e}\n")


_rpc_ids = itertools.count(1)


def rpc(ws, method, params=None):
    mid = next(_rpc_ids)
    ws.send(json.dumps({"jsonrpc": "2.0", "id": mid, "method": method, "params": params or []}))
    while True:
        msg = json.loads(ws.recv())
        if msg.get("id") == mid:
            if "error" in msg:
                raise WSError(f"{method}: {msg['error'].get('message')}")
            return msg.get("result")


def collect():
    ws = WSClient(NAS_HOST, NAS_PORT, WS_PATH)
    try:
        if not rpc(ws, "auth.login_with_api_key", [API_KEY]):
            raise WSError("api key login rejected")
        pools = rpc(ws, "pool.query")
        datasets = rpc(ws, "pool.dataset.query")
        temps = rpc(ws, "disk.temperatures", [[]])
    finally:
        ws.close()
    return pools, datasets, temps


def esc(v):
    return str(v).replace("\\", "\\\\").replace('"', '\\"')


SCRUB_STATES = ["FINISHED", "SCANNING", "CANCELED", "NONE"]


def render(pools, datasets, temps):
    out = []

    def metric(name, mtype, help_):
        out.append(f"# HELP {name} {help_}")
        out.append(f"# TYPE {name} {mtype}")

    metric("truenas_pool_size_bytes", "gauge", "Total pool size in bytes")
    for p in pools:
        out.append(f'truenas_pool_size_bytes{{pool="{esc(p["name"])}"}} {p["size"]}')
    metric("truenas_pool_allocated_bytes", "gauge", "Allocated bytes in pool")
    for p in pools:
        out.append(f'truenas_pool_allocated_bytes{{pool="{esc(p["name"])}"}} {p["allocated"]}')
    metric("truenas_pool_free_bytes", "gauge", "Free bytes in pool")
    for p in pools:
        out.append(f'truenas_pool_free_bytes{{pool="{esc(p["name"])}"}} {p["free"]}')
    metric("truenas_pool_healthy", "gauge", "1 if pool healthy else 0")
    for p in pools:
        out.append(f'truenas_pool_healthy{{pool="{esc(p["name"])}",status="{esc(p["status"])}"}} {1 if p.get("healthy") else 0}')
    metric("truenas_pool_fragmentation_ratio", "gauge", "Pool fragmentation percent")
    for p in pools:
        try:
            out.append(f'truenas_pool_fragmentation_ratio{{pool="{esc(p["name"])}"}} {float(p.get("fragmentation") or 0)}')
        except (TypeError, ValueError):
            pass
    metric("truenas_pool_scrub_state", "gauge", "Scrub/resilver: 1 for the current state label")
    metric("truenas_pool_scrub_errors", "gauge", "Errors from last scrub")
    metric("truenas_pool_scrub_percentage", "gauge", "Scrub progress percent")
    metric("truenas_pool_scrub_end_timestamp_seconds", "gauge", "Unix time the last scrub ended")
    for p in pools:
        scan = p.get("scan") or {}
        state = scan.get("state") or "NONE"
        fn = scan.get("function") or "NONE"
        pool = esc(p["name"])
        for s in SCRUB_STATES:
            out.append(f'truenas_pool_scrub_state{{pool="{pool}",function="{esc(fn)}",state="{s}"}} {1 if state == s else 0}')
        out.append(f'truenas_pool_scrub_errors{{pool="{pool}"}} {scan.get("errors") or 0}')
        out.append(f'truenas_pool_scrub_percentage{{pool="{pool}"}} {scan.get("percentage") or 0}')
        end = scan.get("end_time") or {}
        if isinstance(end, dict) and end.get("$date"):
            out.append(f'truenas_pool_scrub_end_timestamp_seconds{{pool="{pool}"}} {int(end["$date"]) / 1000:.0f}')

    metric("truenas_dataset_used_bytes", "gauge", "Dataset used bytes")
    metric("truenas_dataset_available_bytes", "gauge", "Dataset available bytes")
    for d in datasets:
        if d.get("type") != "FILESYSTEM":
            continue
        name = esc(d["name"])
        used = (d.get("used") or {}).get("parsed")
        avail = (d.get("available") or {}).get("parsed")
        if used is not None:
            out.append(f'truenas_dataset_used_bytes{{dataset="{name}"}} {used}')
        if avail is not None:
            out.append(f'truenas_dataset_available_bytes{{dataset="{name}"}} {avail}')

    metric("truenas_disk_temperature_celsius", "gauge", "Disk temperature in Celsius")
    for disk, temp in (temps or {}).items():
        if temp is not None:
            out.append(f'truenas_disk_temperature_celsius{{disk="{esc(disk)}"}} {temp}')
    return "\n".join(out) + "\n"


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def do_GET(self):
        if self.path != "/metrics":
            self.send_response(404)
            self.end_headers()
            return
        start = time.time()
        try:
            body = render(*collect())
            ok = 1
        # Deliberately broad: any failure must still serve
        # truenas_scrape_success 0 rather than 500 the scrape away.
        except Exception:  # noqa: BLE001
            body = ""
            ok = 0
            traceback.print_exc()
        body += (
            "# HELP truenas_scrape_success 1 if the last scrape of the TrueNAS API succeeded\n"
            "# TYPE truenas_scrape_success gauge\n"
            f"truenas_scrape_success {ok}\n"
            "# HELP truenas_scrape_duration_seconds Duration of the TrueNAS API scrape\n"
            "# TYPE truenas_scrape_duration_seconds gauge\n"
            f"truenas_scrape_duration_seconds {time.time() - start:.3f}\n"
        )
        data = body.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", LISTEN), Handler).serve_forever()  # noqa: S104 - scraped across the pod network
