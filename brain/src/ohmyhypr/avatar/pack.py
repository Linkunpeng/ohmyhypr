"""Avatar packs: a directory with avatar.toml describing a model and its behaviour.

Packs never contain the model itself; `root` points at wherever the model lives
(models are usually not redistributable).
"""

from __future__ import annotations

import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .. import paths

FORMATS = {".pmx": "pmx"}


class PackError(RuntimeError):
    pass


@dataclass
class Pack:
    id: str
    dir: Path
    root: Path
    data: dict[str, Any]

    @property
    def name(self) -> str:
        return self.data["avatar"].get("name", self.id)

    @property
    def model(self) -> Path:
        return paths.expand(self.data["avatar"]["model"], self.root)

    @property
    def window(self) -> dict[str, int]:
        return {"width": 420, "height": 640, **self.data.get("window", {})}

    @property
    def persona(self) -> str:
        return self.data.get("persona", {}).get("prompt", "")

    def assets(self) -> list[Path]:
        motions = self.data.get("motions", {})
        files = [self.model, *(paths.expand(p, self.root) for p in motions.get("idle", []))]
        files += [paths.expand(a["file"], self.root) for a in self.data.get("actions", {}).values()]
        return files

    def check(self) -> list[str]:
        problems = [f"missing: {p}" for p in self.assets() if not p.is_file()]
        if self.model.suffix.lower() not in FORMATS:
            problems.append(f"unsupported model format: {self.model.suffix}")
        return problems

    def manifest(self, url_for) -> dict[str, Any]:
        """Renderer manifest; `url_for(path)` maps a local file to a served URL."""
        d = self.data
        motions = d.get("motions", {})
        return {
            "id": self.id,
            "name": self.name,
            "format": FORMATS.get(self.model.suffix.lower(), "pmx"),
            "model": url_for(self.model),
            "camera": {"target_y": 11.0, "distance": 32.0, "fov": 0.6, **d.get("camera", {})},
            "expressions": {
                k: (v if isinstance(v, list) else [v]) for k, v in d.get("expressions", {}).items()
            },
            "idle": [url_for(paths.expand(p, self.root)) for p in motions.get("idle", [])],
            "idle_interval": motions.get("idle_interval", 25),
            "actions": {
                name: {"url": url_for(paths.expand(a["file"], self.root)), "loop": a.get("loop", False)}
                for name, a in d.get("actions", {}).items()
            },
            "lines": d.get("lines", {}),
        }


def load(name_or_path: str) -> Pack:
    candidate = Path(name_or_path).expanduser()
    if candidate.is_dir():
        candidate = candidate / "avatar.toml"
    toml_path = candidate if candidate.is_file() else paths.search("avatars", name_or_path, "avatar.toml")
    if toml_path is None:
        raise PackError(f"avatar pack not found: {name_or_path} (looked in {paths.CONFIG / 'avatars'}, {paths.REPO / 'avatars'})")
    with toml_path.open("rb") as f:
        data = tomllib.load(f)
    if "avatar" not in data or "model" not in data["avatar"]:
        raise PackError(f"{toml_path}: [avatar].model is required")
    pack_dir = toml_path.parent
    root = paths.expand(data["avatar"].get("root", "."), pack_dir)
    return Pack(id=pack_dir.name, dir=pack_dir, root=root, data=data)
