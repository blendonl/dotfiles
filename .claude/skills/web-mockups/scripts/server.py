#!/usr/bin/env python3
"""Web mockups server: static files + SSE live-reload + auto-index.

Serves ~/.claude/mockups/ at http://127.0.0.1:4280/. Each top-level subdirectory
containing an index.html is a mockup; the root path shows a generated index of them.
Any HTML response gets a tiny <script> appended that listens on /__reload (SSE)
and calls location.reload() when the server notices a file change.

Stdlib only. Meant to be spawned once by ensure_server.py and left running.
"""
from __future__ import annotations

import html
import mimetypes
import os
import queue
import signal
import sys
import threading
import time
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HOST = "127.0.0.1"
PORT = 4280
MOCKUPS_ROOT = Path.home() / ".claude" / "mockups"
PID_FILE = MOCKUPS_ROOT / ".server.pid"
POLL_INTERVAL = 0.5

RELOAD_SNIPPET = (
    b'<script>new EventSource("/__reload").onmessage=()=>location.reload()</script>'
)

_clients_lock = threading.Lock()
_clients: "set[queue.Queue[str]]" = set()


def snapshot_mtimes(root: Path) -> dict:
    """Walk `root` and return {path: mtime}. Skips dotfiles and dot-dirs so our own
    PID / log file don't cause spurious reloads."""
    out = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if not d.startswith(".")]
        for name in filenames:
            if name.startswith("."):
                continue
            p = os.path.join(dirpath, name)
            try:
                out[p] = os.path.getmtime(p)
            except OSError:
                pass
    return out


def watcher_loop() -> None:
    prev = snapshot_mtimes(MOCKUPS_ROOT)
    while True:
        time.sleep(POLL_INTERVAL)
        try:
            cur = snapshot_mtimes(MOCKUPS_ROOT)
        except Exception:
            continue
        if cur != prev:
            prev = cur
            broadcast("reload")


def broadcast(event: str) -> None:
    with _clients_lock:
        dead = []
        for q in _clients:
            try:
                q.put_nowait(event)
            except Exception:
                dead.append(q)
        for q in dead:
            _clients.discard(q)


def safe_join(root: Path, relpath: str) -> "Path | None":
    """Resolve `relpath` under `root` and return it, or None if it escapes root."""
    candidate = (root / relpath.lstrip("/")).resolve()
    try:
        candidate.relative_to(root.resolve())
    except ValueError:
        return None
    return candidate


def render_index() -> bytes:
    entries = []
    if MOCKUPS_ROOT.exists():
        for child in sorted(MOCKUPS_ROOT.iterdir()):
            if child.name.startswith(".") or not child.is_dir():
                continue
            if not (child / "index.html").exists():
                continue
            mtime = datetime.fromtimestamp(child.stat().st_mtime).strftime("%Y-%m-%d %H:%M")
            name = html.escape(child.name)
            entries.append(
                f'<li><a href="/{name}/"><span class="name">{name}</span>'
                f'<span class="mtime">{mtime}</span></a></li>'
            )
    body = (
        f"<ul>{''.join(entries)}</ul>"
        if entries
        else '<p class="empty">No mockups yet. Ask Claude to create one, then refresh.</p>'
    )
    page = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Mockups</title>
<style>
  :root {{ color-scheme: light dark; }}
  body {{ font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
         max-width: 720px; margin: 4rem auto; padding: 0 1.5rem;
         line-height: 1.5; color: #111; background: #fafafa; }}
  h1 {{ font-size: 1.5rem; margin: 0 0 1.5rem; }}
  ul {{ list-style: none; padding: 0; margin: 0; }}
  li {{ margin: 0.5rem 0; }}
  li a {{ display: flex; justify-content: space-between; align-items: center;
          padding: 0.75rem 1rem; border-radius: 8px;
          background: #fff; text-decoration: none; color: inherit;
          box-shadow: 0 1px 2px rgba(0,0,0,0.06); }}
  li a:hover {{ background: #f0f0f0; }}
  .name {{ font-weight: 500; }}
  .mtime {{ font-size: 0.85rem; color: #666; font-variant-numeric: tabular-nums; }}
  .empty {{ color: #888; }}
  @media (prefers-color-scheme: dark) {{
    body {{ color: #eee; background: #111; }}
    li a {{ background: #1a1a1a; box-shadow: none; }}
    li a:hover {{ background: #222; }}
    .mtime {{ color: #888; }}
  }}
</style>
</head>
<body>
<h1>Mockups</h1>
{body}
</body>
</html>"""
    return page.encode("utf-8")


def inject_reload(html_bytes: bytes) -> bytes:
    idx = html_bytes.rfind(b"</body>")
    if idx == -1:
        return html_bytes + RELOAD_SNIPPET
    return html_bytes[:idx] + RELOAD_SNIPPET + html_bytes[idx:]


class Handler(BaseHTTPRequestHandler):
    server_version = "WebMockups/1.0"

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def do_GET(self):
        path = self.path.split("?", 1)[0].split("#", 1)[0]

        if path == "/__reload":
            return self.serve_sse()
        if path == "/health":
            return self.send_bytes(200, b"ok", "text/plain; charset=utf-8")
        if path == "/favicon.ico":
            self.send_response(204)
            self.end_headers()
            return
        if path in ("/", ""):
            return self.send_bytes(
                200, render_index(), "text/html; charset=utf-8", inject=False
            )

        target = safe_join(MOCKUPS_ROOT, path)
        if target is None:
            return self.send_error(404, "Not Found")

        # Redirect /slug -> /slug/ so relative hrefs in index.html resolve correctly.
        if target.is_dir() and not path.endswith("/"):
            self.send_response(301)
            self.send_header("Location", path + "/")
            self.end_headers()
            return

        if target.is_dir():
            idx = target / "index.html"
            if not idx.exists():
                return self.send_error(404, "No index.html in this mockup")
            target = idx

        if not target.exists() or not target.is_file():
            return self.send_error(404, "Not Found")

        ctype, _ = mimetypes.guess_type(target.name)
        if ctype is None:
            ctype = "application/octet-stream"
        if ctype.startswith("text/") and "charset=" not in ctype:
            ctype += "; charset=utf-8"
        data = target.read_bytes()
        is_html = target.suffix.lower() in (".html", ".htm")
        self.send_bytes(200, data, ctype, inject=is_html)

    def send_bytes(self, status: int, body: bytes, ctype: str, inject: bool = False):
        if inject:
            body = inject_reload(body)
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def serve_sse(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Connection", "keep-alive")
        self.end_headers()
        q: "queue.Queue[str]" = queue.Queue()
        with _clients_lock:
            _clients.add(q)
        try:
            self.wfile.write(b": connected\n\n")
            self.wfile.flush()
            while True:
                try:
                    event = q.get(timeout=15)
                    self.wfile.write(f"data: {event}\n\n".encode("utf-8"))
                    self.wfile.flush()
                except queue.Empty:
                    self.wfile.write(b": ping\n\n")
                    self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError):
            pass
        finally:
            with _clients_lock:
                _clients.discard(q)


def write_pid() -> None:
    PID_FILE.write_text(str(os.getpid()))


def cleanup_pid(*_) -> None:
    try:
        PID_FILE.unlink()
    except FileNotFoundError:
        pass
    sys.exit(0)


def main() -> int:
    MOCKUPS_ROOT.mkdir(parents=True, exist_ok=True)
    if PID_FILE.exists():
        try:
            pid = int(PID_FILE.read_text().strip())
            os.kill(pid, 0)
            print(f"Server already running (pid {pid})", file=sys.stderr)
            return 1
        except (ValueError, ProcessLookupError):
            PID_FILE.unlink(missing_ok=True)
        except PermissionError:
            # PID exists but owned by another user — treat as live, refuse to start.
            print(f"Port {PORT} appears taken by another user's process", file=sys.stderr)
            return 1

    write_pid()
    signal.signal(signal.SIGTERM, cleanup_pid)
    signal.signal(signal.SIGINT, cleanup_pid)

    threading.Thread(target=watcher_loop, daemon=True).start()

    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Serving {MOCKUPS_ROOT} at http://{HOST}:{PORT}/", file=sys.stderr)
    try:
        server.serve_forever()
    finally:
        cleanup_pid()
    return 0


if __name__ == "__main__":
    sys.exit(main())
