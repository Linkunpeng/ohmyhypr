"""Lease client for the local GPU Keeper, which arbitrates the GPU between
LocalAI, ComfyUI and other runtimes.

POST /acquire {"owner", "wait_timeout", "ttl"} -> {"lease_id"}
POST /renew   {"lease_id"}       (every ttl/3 while running)
POST /release {"owner"}          (only if we acquired)
"""

from __future__ import annotations

import json
import sys
import threading
import urllib.error
import urllib.request
from collections.abc import Iterator
from contextlib import contextmanager
from typing import Any


class GpuBusy(RuntimeError):
    pass


def _post(url: str, body: dict[str, Any], timeout: float) -> dict[str, Any]:
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        raw = resp.read()
    return json.loads(raw) if raw else {}


@contextmanager
def lease(cfg: dict[str, Any]) -> Iterator[str | None]:
    """Yield a lease id, or None when running unmanaged."""
    if not cfg.get("enabled", True):
        yield None
        return

    base, owner, ttl = cfg["url"].rstrip("/"), cfg["owner"], cfg["ttl"]
    try:
        res = _post(
            f"{base}/acquire",
            {"owner": owner, "wait_timeout": cfg["wait_timeout"], "ttl": ttl},
            timeout=cfg["wait_timeout"] + 5,
        )
    except urllib.error.HTTPError as e:
        raise GpuBusy(f"GPU Keeper refused lease (HTTP {e.code})") from e
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        if cfg.get("required"):
            raise GpuBusy(f"GPU Keeper unreachable: {e}") from e
        print(f"omh: GPU Keeper unreachable ({e}); running unmanaged", file=sys.stderr)
        yield None
        return

    lease_id = res.get("lease_id")
    if not lease_id:
        raise GpuBusy(f"GPU Keeper returned no lease_id: {res}")

    stop = threading.Event()

    def renew() -> None:
        while not stop.wait(ttl / 3):
            try:
                _post(f"{base}/renew", {"lease_id": lease_id}, timeout=5)
            except Exception as e:  # noqa: BLE001 - keep the request alive, just report
                print(f"omh: lease renew failed: {e}", file=sys.stderr)

    renewer = threading.Thread(target=renew, daemon=True)
    renewer.start()
    try:
        yield lease_id
    finally:
        stop.set()
        try:
            _post(f"{base}/release", {"owner": owner}, timeout=5)
        except Exception as e:  # noqa: BLE001
            print(f"omh: lease release failed: {e}", file=sys.stderr)
