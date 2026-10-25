"""Minimal PMX 2.0/2.1 reader: header, bones and morphs (for `omh avatar inspect`).

Only parses what pack authors need: names and counts. Geometry is skipped.
Spec: https://gist.github.com/felixjones/f8a06bd48f9da9a4539f
"""

from __future__ import annotations

import struct
from dataclasses import dataclass, field
from pathlib import Path

MORPH_KINDS = {0: "group", 1: "vertex", 2: "bone", 3: "uv", 4: "uv1", 5: "uv2", 6: "uv3",
               7: "uv4", 8: "material", 9: "flip", 10: "impulse"}
PANELS = {0: "system", 1: "eyebrow", 2: "eye", 3: "mouth", 4: "other"}


@dataclass
class Morph:
    name: str
    name_en: str
    panel: str
    kind: str


@dataclass
class PmxInfo:
    version: float
    name: str
    comment: str
    vertices: int
    faces: int
    textures: list[str] = field(default_factory=list)
    materials: int = 0
    bones: list[str] = field(default_factory=list)
    morphs: list[Morph] = field(default_factory=list)


class _Reader:
    def __init__(self, data: bytes) -> None:
        self.d = data
        self.p = 0

    def take(self, n: int) -> bytes:
        b = self.d[self.p : self.p + n]
        self.p += n
        return b

    def skip(self, n: int) -> None:
        self.p += n

    def unpack(self, fmt: str):
        size = struct.calcsize(fmt)
        v = struct.unpack_from("<" + fmt, self.d, self.p)
        self.p += size
        return v

    def i32(self) -> int:
        return self.unpack("i")[0]

    def u8(self) -> int:
        return self.unpack("B")[0]

    def index(self, size: int) -> int:
        return self.unpack({1: "b", 2: "h", 4: "i"}[size])[0]


def read(path: str | Path) -> PmxInfo:
    r = _Reader(Path(path).read_bytes())
    if r.take(4) != b"PMX ":
        raise ValueError(f"{path}: not a PMX file")
    version = r.unpack("f")[0]
    g = list(r.take(r.u8()))
    encoding = "utf-16-le" if g[0] == 0 else "utf-8"
    extra_uv, vsize, tsize, msize, bsize, morph_size, _rsize = g[1:8]

    def text() -> str:
        return r.take(r.i32()).decode(encoding, "replace")

    name, _name_en, comment, _comment_en = text(), text(), text(), text()

    # vertices
    n_vert = r.i32()
    for _ in range(n_vert):
        r.skip(4 * 8 + 16 * extra_uv)  # pos, normal, uv, extra uv
        deform = r.u8()
        if deform == 0:
            r.skip(bsize)
        elif deform == 1:
            r.skip(bsize * 2 + 4)
        elif deform in (2, 4):
            r.skip(bsize * 4 + 16)
        elif deform == 3:
            r.skip(bsize * 2 + 4 + 36)
        else:
            raise ValueError(f"unknown deform type {deform}")
        r.skip(4)  # edge scale

    n_face_idx = r.i32()
    r.skip(n_face_idx * vsize)

    textures = [text() for _ in range(r.i32())]

    n_mat = r.i32()
    for _ in range(n_mat):
        text(), text()
        r.skip(16 + 12 + 4 + 12 + 1 + 16 + 4)  # diffuse, specular, power, ambient, flag, edge
        r.skip(tsize * 2 + 1)  # texture, sphere, sphere mode
        shared_toon = r.u8()
        r.skip(1 if shared_toon else tsize)
        text()  # memo
        r.skip(4)  # face count

    bones = []
    for _ in range(r.i32()):
        bones.append(text())
        text()
        r.skip(12 + bsize + 4)  # position, parent, layer
        flag = r.unpack("H")[0]
        r.skip(bsize if flag & 0x0001 else 12)  # tail
        if flag & 0x0300:
            r.skip(bsize + 4)  # append parent + ratio
        if flag & 0x0400:
            r.skip(12)  # fixed axis
        if flag & 0x0800:
            r.skip(24)  # local axes
        if flag & 0x2000:
            r.skip(4)  # external parent
        if flag & 0x0020:  # IK
            r.skip(bsize + 4 + 4)
            for _ in range(r.i32()):
                r.skip(bsize)
                if r.u8():
                    r.skip(24)

    offset_size = {0: morph_size + 4, 1: vsize + 12, 2: bsize + 28, 3: vsize + 16, 4: vsize + 16,
                   5: vsize + 16, 6: vsize + 16, 7: vsize + 16, 8: msize + 1 + 112,
                   9: morph_size + 4, 10: _rsize + 1 + 24}
    morphs = []
    for _ in range(r.i32()):
        m_name, m_en = text(), text()
        panel, kind = r.u8(), r.u8()
        count = r.i32()
        r.skip(count * offset_size[kind])
        morphs.append(Morph(m_name, m_en, PANELS.get(panel, str(panel)), MORPH_KINDS.get(kind, str(kind))))

    return PmxInfo(version, name, comment.strip(), n_vert, n_face_idx // 3, textures, n_mat, bones, morphs)
