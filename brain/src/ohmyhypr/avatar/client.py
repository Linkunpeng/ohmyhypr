"""Version 1 avatar adapter protocol over a Unix NDJSON socket."""

from __future__ import annotations

import json
import os
import socket
from pathlib import Path
from typing import Any

from .. import paths


class AvatarError(RuntimeError):
    pass


def socket_path(cfg: dict[str, Any]) -> Path:
    value = cfg.get("avatar", {}).get("socket", "")
    return Path(os.path.expandvars(value)).expanduser() if value else paths.AVATAR_SOCKET


def send(cfg: dict[str, Any], cmd: dict[str, Any], timeout: float = 12) -> dict[str, Any]:
    path = socket_path(cfg)
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
            sock.settimeout(timeout)
            sock.connect(str(path))
            sock.sendall((json.dumps(cmd, ensure_ascii=False) + "\n").encode())
            with sock.makefile("rb") as stream:
                line = stream.readline(1024 * 1024 + 1)
            if not line or len(line) > 1024 * 1024 or not line.endswith(b"\n"):
                raise AvatarError("invalid avatar adapter response")
            reply = json.loads(line)
    except (OSError, ValueError) as e:
        raise AvatarError(f"avatar adapter unavailable at {path}: {e}") from e
    if not isinstance(reply, dict) or not isinstance(reply.get("ok"), bool):
        raise AvatarError("invalid avatar adapter response")
    if not reply["ok"]:
        raise AvatarError(str(reply.get("error", "avatar adapter error")))
    return reply
