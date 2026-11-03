"""Streaming chat through OpenAI- or Anthropic-compatible HTTP APIs."""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.parse
import urllib.request
from collections.abc import Iterator
from typing import Any


class ProviderError(RuntimeError):
    pass


def resolve(cfg: dict[str, Any], name: str | None = None) -> tuple[str, dict[str, Any]]:
    name = name or cfg["ai"]["default_provider"]
    provider = cfg.get("providers", {}).get(name)
    if not isinstance(provider, dict):
        raise ProviderError(f"provider {name!r} is not configured; see config/ohmyhypr.example.toml")
    if provider.get("type") not in ("openai", "anthropic"):
        raise ProviderError(f"provider {name!r}: type must be 'openai' or 'anthropic'")
    url = provider.get("base_url", "")
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme not in ("http", "https") or not parsed.hostname or parsed.username or parsed.password or parsed.query or parsed.fragment:
        raise ProviderError(f"provider {name!r}: base_url must be an HTTP(S) URL without credentials, query, or fragment")
    if not provider.get("model"):
        raise ProviderError(f"provider {name!r}: model is required")
    return name, provider


def _events(resp: Any) -> Iterator[str]:
    """Read SSE records, including multi-line data and a final unterminated record."""
    data: list[str] = []
    for raw in resp:
        line = raw.decode("utf-8").rstrip("\r\n")
        if not line:
            if data:
                yield "\n".join(data)
                data.clear()
        elif line.startswith("data:"):
            data.append(line[5:].removeprefix(" "))
    if data:
        yield "\n".join(data)


def chat(cfg: dict[str, Any], messages: list[dict[str, str]], name: str | None = None) -> Iterator[str]:
    name, provider = resolve(cfg, name)
    kind = provider["type"]
    key_env = provider.get("api_key_env", "")
    key = provider.get("api_key", "")
    if key_env:
        key = os.environ.get(key_env, "")
        if not key:
            raise ProviderError(f"provider {name!r}: environment variable {key_env!r} is not set")

    headers = {"Content-Type": "application/json", "Accept": "text/event-stream"}
    body: dict[str, Any] = {"model": provider["model"], "stream": True}
    if kind == "openai":
        if key:
            headers["Authorization"] = f"Bearer {key}"
        body["messages"] = messages
        endpoint = "chat/completions"
    else:
        if key:
            headers["x-api-key"] = key
        headers["anthropic-version"] = provider.get("anthropic_version", "2023-06-01")
        body["max_tokens"] = provider.get("max_tokens", 1024)
        system = [m["content"] for m in messages if m["role"] == "system"]
        if system:
            body["system"] = "\n\n".join(system)
        body["messages"] = [m for m in messages if m["role"] != "system"]
        endpoint = "messages"

    req = urllib.request.Request(
        f"{provider['base_url'].rstrip('/')}/{endpoint}",
        data=json.dumps(body).encode(), headers=headers, method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=provider.get("timeout", 120)) as resp:
            for data in _events(resp):
                if data == "[DONE]":
                    break
                event = json.loads(data)
                if event.get("error") or event.get("type") == "error":
                    raise ProviderError(f"provider {name!r}: streaming API returned an error")
                if kind == "openai":
                    for choice in event.get("choices", []):
                        if text := choice.get("delta", {}).get("content"):
                            yield text
                elif event.get("type") == "content_block_delta":
                    delta = event.get("delta", {})
                    if delta.get("type") == "text_delta" and (text := delta.get("text")):
                        yield text
    except urllib.error.HTTPError as e:
        e.close()
        raise ProviderError(f"provider {name!r}: HTTP {e.code} from API") from e
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        raise ProviderError(f"provider {name!r}: unable to connect to API ({e.reason if isinstance(e, urllib.error.URLError) else e})") from e
