"""`omh avatar …` subcommands."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

from .. import paths
from . import client, pack, pmx

SYSTEM_PYTHON = "/usr/bin/python3"  # PyGObject / WebKit live in the system site-packages


def register(sub: argparse._SubParsersAction) -> None:
    p = sub.add_parser("avatar", help="interactive 3D avatar")
    av = p.add_subparsers(dest="avatar_cmd", required=True)

    run = av.add_parser("run", help="start the avatar window")
    run.add_argument("--pack", help="pack id or path (default: current theme / config)")
    run.add_argument("--detach", action="store_true", help="run in the background, log to state dir")

    for name, help_ in [("say", "show a line in the speech bubble"), ("ask", "ask the avatar (in character)")]:
        av.add_parser(name, help=help_).add_argument("text", nargs="+")
    av.add_parser("motion", help="play an action / `next` idle pose / `stop`").add_argument("name")
    av.add_parser("expression", help="smile | angry | sad | surprise | wink | thinking").add_argument("name")
    for name in ("chat", "show", "hide", "toggle", "status", "quit"):
        av.add_parser(name)
    av.add_parser("reload", help="reload (optionally switch pack)").add_argument("pack", nargs="?")
    av.add_parser("list", help="list avatar packs")
    av.add_parser("inspect", help="list morphs/bones of a PMX file or pack").add_argument("target")


def run(args: argparse.Namespace) -> int:
    cmd = args.avatar_cmd
    if cmd == "run":
        return _run_host(args)
    if cmd == "list":
        for name in paths.available("avatars", "avatar.toml"):
            p = pack.load(name)
            problems = p.check()
            print(f"{name:<16} {p.name:<12} {'ok' if not problems else problems[0]}")
        return 0
    if cmd == "inspect":
        return _inspect(args.target)

    msg: dict = {"cmd": cmd}
    if cmd in ("say", "ask"):
        msg["text"] = " ".join(args.text)
    elif cmd in ("motion", "expression"):
        msg["name"] = args.name
    elif cmd == "reload" and args.pack:
        msg["pack"] = args.pack
    try:
        reply = client.send(msg)
    except client.NotRunning as e:
        print(f"omh: {e}", file=sys.stderr)
        return 1
    if cmd == "status" or not reply.get("ok"):
        print(json.dumps(reply, ensure_ascii=False))
    return 0 if reply.get("ok") else 1


def _run_host(args: argparse.Namespace) -> int:
    argv = [SYSTEM_PYTHON, "-m", "ohmyhypr.avatar.host"]
    if args.pack:
        argv += ["--pack", args.pack]
    env = {**os.environ, "PYTHONPATH": str(paths.REPO / "brain" / "src")}
    if not args.detach:
        os.execve(SYSTEM_PYTHON, argv, env)
    paths.STATE.mkdir(parents=True, exist_ok=True)
    log = (paths.STATE / "avatar.log").open("ab")
    subprocess.Popen(argv, env=env, stdout=log, stderr=log, stdin=subprocess.DEVNULL, start_new_session=True)
    print(f"avatar started (log: {paths.STATE / 'avatar.log'})")
    return 0


def _inspect(target: str) -> int:
    path = None
    try:
        p = pack.load(target)
        path = p.model
        print(f"pack {p.id}: {p.name}  model={path}")
        for problem in p.check():
            print(f"  ! {problem}")
    except pack.PackError:
        path = target
    info = pmx.read(path)
    print(f"{info.name}  PMX {info.version:.1f}  {info.vertices} verts  {info.faces} faces  "
          f"{info.materials} materials  {len(info.bones)} bones  {len(info.morphs)} morphs")
    by_panel: dict[str, list[str]] = {}
    for m in info.morphs:
        by_panel.setdefault(m.panel, []).append(m.name)
    for panel, names in by_panel.items():
        print(f"  {panel:<8} {'  '.join(names)}")
    key_bones = [b for b in info.bones if b in ("全ての親", "センター", "上半身", "首", "頭", "両目")]
    print(f"  bones    {'  '.join(key_bones)} …")
    return 0
