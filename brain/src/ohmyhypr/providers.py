"""Model providers. Local = LocalAI (OpenAI-compatible) under a GPU lease;
cloud = Claude via the `claude` CLI."""

from __future__ import annotations

import json
import subprocess
import urllib.request
from collections.abc import Iterator
from typing import Any

from . import gpu_keeper


def local_chat(cfg: dict[str, Any], messages: list[dict[str, str]]) -> Iterator[str]:
    local = cfg["local"]
    body = {
        "model": local["chat_model"],
        "messages": messages,
        "stream": True,
        "reasoning_effort": "none",
    }
    req = urllib.request.Request(
        f"{local['base_url'].rstrip('/')}/chat/completions",
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with gpu_keeper.lease(cfg["gpu_keeper"]):
        with urllib.request.urlopen(req, timeout=local["timeout"]) as resp:
            for raw in resp:
                line = raw.decode().strip()
                if not line.startswith("data:"):
                    continue
                data = line.removeprefix("data:").strip()
                if data == "[DONE]":
                    break
                delta = json.loads(data)["choices"][0].get("delta", {})
                if text := delta.get("content"):
                    yield text


def cloud_chat(cfg: dict[str, Any], prompt: str) -> Iterator[str]:
    proc = subprocess.Popen(
        [*cfg["cloud"]["command"], prompt],
        stdout=subprocess.PIPE,
        text=True,
    )
    assert proc.stdout is not None
    yield from proc.stdout
    proc.wait()
