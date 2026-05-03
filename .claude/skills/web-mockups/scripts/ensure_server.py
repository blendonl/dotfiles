#!/usr/bin/env python3
"""Ensure the web-mockups server is running. Idempotent: safe to call repeatedly.

On success, prints the server URL (http://127.0.0.1:4280/) to stdout and exits 0 —
whether we started the server ourselves or it was already up. On failure, tails the
server log to stderr and exits 1.
"""
from __future__ import annotations

import os
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

HOST = "127.0.0.1"
PORT = 4280
URL = f"http://{HOST}:{PORT}/"

HERE = Path(__file__).resolve().parent
SERVER = HERE / "server.py"
MOCKUPS_ROOT = Path.home() / ".claude" / "mockups"
PID_FILE = MOCKUPS_ROOT / ".server.pid"
LOG_FILE = MOCKUPS_ROOT / ".server.log"


def health_ok() -> bool:
    try:
        with urllib.request.urlopen(f"{URL}health", timeout=0.5) as r:
            return r.status == 200 and r.read(2) == b"ok"
    except Exception:
        return False


def pid_alive() -> bool:
    if not PID_FILE.exists():
        return False
    try:
        pid = int(PID_FILE.read_text().strip())
        os.kill(pid, 0)
        return True
    except Exception:
        return False


def main() -> int:
    MOCKUPS_ROOT.mkdir(parents=True, exist_ok=True)

    if pid_alive() and health_ok():
        print(URL)
        return 0

    # Stale PID? server.py removes it on startup; no need to clean up here.
    with open(LOG_FILE, "ab") as log:
        subprocess.Popen(
            [sys.executable, str(SERVER)],
            stdout=log,
            stderr=log,
            stdin=subprocess.DEVNULL,
            start_new_session=True,
            close_fds=True,
        )

    deadline = time.time() + 2.5
    while time.time() < deadline:
        if health_ok():
            print(URL)
            return 0
        time.sleep(0.1)

    sys.stderr.write("Failed to start mockup server. Last log lines:\n")
    try:
        tail = LOG_FILE.read_text().splitlines()[-20:]
        sys.stderr.write("\n".join(tail) + "\n")
    except Exception:
        pass
    return 1


if __name__ == "__main__":
    sys.exit(main())
