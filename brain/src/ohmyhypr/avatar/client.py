"""Talk to a running avatar host over its control socket (NDJSON)."""

from __future__ import annotations

import json
import socket
from typing import Any

from .. import paths


class NotRunning(RuntimeError):
    pass


def send(cmd: dict[str, Any], timeout: float = 12) -> dict[str, Any]:
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(timeout)
            s.connect(str(paths.AVATAR_SOCKET))
            s.sendall((json.dumps(cmd, ensure_ascii=False) + "\n").encode())
            buf = b""
            while not buf.endswith(b"\n"):
                chunk = s.recv(4096)
                if not chunk:
                    break
                buf += chunk
    except (FileNotFoundError, ConnectionRefusedError) as e:
        raise NotRunning("avatar is not running (start it with `omh avatar run`)") from e
    return json.loads(buf or b"{}")


def running() -> bool:
    try:
        return bool(send({"cmd": "status"}, timeout=2).get("ok"))
    except (NotRunning, OSError, json.JSONDecodeError):
        return False
