"""Local iwd and BlueZ status and actions for the connectivity menu."""
from __future__ import annotations

import json
import re
import subprocess
from typing import Any


class ConnectivityError(RuntimeError):
    pass


def _call(*args: str, timeout: int = 8) -> str:
    try:
        result = subprocess.run(["busctl", "--system", *args], capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired) as e:
        raise ConnectivityError("Could not contact the system service") from e
    if result.returncode:
        raise ConnectivityError(result.stderr.strip() or "System service request failed")
    return result.stdout


def _objects(service: str) -> dict[str, Any] | None:
    try:
        data = json.loads(_call("--json=short", "call", service, "/", "org.freedesktop.DBus.ObjectManager", "GetManagedObjects"))
        result = data["data"][0]
        return result if isinstance(result, dict) else None
    except (ConnectivityError, ValueError, KeyError, IndexError, TypeError):
        return None


def _props(interfaces: dict, name: str) -> dict[str, Any]:
    return {key: value.get("data") for key, value in interfaces.get(name, {}).items() if isinstance(value, dict)}


def _device(objects: dict[str, Any], interface: str) -> tuple[str, dict] | None:
    return next(((path, _props(interfaces, interface)) for path, interfaces in objects.items() if interface in interfaces), None)


def snapshot() -> dict[str, Any]:
    wifi: dict[str, Any] = {"available": False, "enabled": False, "interface": "", "connected": "", "networks": []}
    bluetooth: dict[str, Any] = {"available": False, "enabled": False, "devices": []}
    iwd = _objects("net.connman.iwd")
    if iwd is not None and (device := _device(iwd, "net.connman.iwd.Device")):
        path, props = device
        station = _props(iwd[path], "net.connman.iwd.Station")
        wifi.update(available=True, enabled=bool(props.get("Powered")), interface=props.get("Name", ""),
                    state=station.get("State", "unknown"))
        known = {(_props(v, "net.connman.iwd.KnownNetwork").get("Name"),
                  _props(v, "net.connman.iwd.KnownNetwork").get("Type"))
                 for v in iwd.values() if "net.connman.iwd.KnownNetwork" in v}
        signals: dict[str, int] = {}
        if station and wifi["enabled"]:
            try:
                data = json.loads(_call("--json=short", "call", "net.connman.iwd", path,
                                        "net.connman.iwd.Station", "GetOrderedNetworks"))
                signals = {entry[0]: round(entry[1] / 100) for entry in data["data"][0]}
            except (ConnectivityError, ValueError, KeyError, IndexError, TypeError):
                pass
        for network_path, interfaces in iwd.items():
            if "net.connman.iwd.Network" not in interfaces:
                continue
            net = _props(interfaces, "net.connman.iwd.Network")
            if net.get("Device") != path or not net.get("Name"):
                continue
            item = {"path": network_path, "name": net["Name"], "security": net.get("Type", ""),
                    "connected": bool(net.get("Connected")), "known": (net["Name"], net.get("Type")) in known,
                    "signal": signals.get(network_path)}
            wifi["networks"].append(item)
            if item["connected"]:
                wifi["connected"] = item["name"]
        wifi["networks"].sort(key=lambda n: (not n["connected"], -(n["signal"] if n["signal"] is not None else -999), n["name"].casefold()))
    bluez = _objects("org.bluez")
    if bluez is not None and (adapter := _device(bluez, "org.bluez.Adapter1")):
        path, props = adapter
        bluetooth.update(available=True, enabled=bool(props.get("Powered")))
        for devpath, interfaces in bluez.items():
            if "org.bluez.Device1" not in interfaces:
                continue
            dev = _props(interfaces, "org.bluez.Device1")
            if dev.get("Adapter") != path:
                continue
            if not re.fullmatch(r"(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}", str(dev.get("Address", ""))):
                continue
            bluetooth["devices"].append({"path": devpath, "name": dev.get("Alias") or dev.get("Name") or "Bluetooth device",
                                         "address": dev.get("Address", ""), "connected": bool(dev.get("Connected")),
                                         "paired": bool(dev.get("Paired"))})
        bluetooth["devices"].sort(key=lambda d: (not d["connected"], not d["paired"], d["name"].casefold()))
        bluetooth["devices"] = bluetooth["devices"][:50]
    return {"wifi": wifi, "bluetooth": bluetooth}


def action(kind: str, operation: str, target: str = "") -> None:
    if kind not in ("wifi", "bluetooth"):
        raise ConnectivityError("Unknown device type")
    service = "net.connman.iwd" if kind == "wifi" else "org.bluez"
    objects = _objects(service)
    if objects is None:
        raise ConnectivityError("System service is unavailable")
    iface = "net.connman.iwd.Device" if kind == "wifi" else "org.bluez.Adapter1"
    device = _device(objects, iface)
    if device is None:
        raise ConnectivityError("No compatible adapter found")
    path, _ = device
    if operation in ("on", "off"):
        _call("set-property", service, path, iface, "Powered", "b", "true" if operation == "on" else "false")
    elif kind == "wifi" and operation == "scan":
        _call("call", service, path, "net.connman.iwd.Station", "Scan")
    elif kind == "wifi" and operation == "disconnect":
        _call("call", service, path, "net.connman.iwd.Station", "Disconnect")
    elif kind == "wifi" and operation == "connect":
        interfaces = objects.get(target, {})
        net = _props(interfaces, "net.connman.iwd.Network")
        if net.get("Device") != path:
            raise ConnectivityError("Network is no longer available")
        _call("call", service, target, "net.connman.iwd.Network", "Connect", timeout=30)
    elif kind == "bluetooth" and operation == "scan":
        try:
            result = subprocess.run(["bluetoothctl", "--timeout", "8", "scan", "on"], capture_output=True, text=True, timeout=12)
        except (OSError, subprocess.TimeoutExpired) as e:
            raise ConnectivityError("Bluetooth scan failed") from e
        if result.returncode:
            raise ConnectivityError(result.stderr.strip() or "Bluetooth scan failed")
    elif kind == "bluetooth" and operation in ("connect", "disconnect"):
        if not re.fullmatch(r"/org/bluez/hci[0-9]+/dev_[0-9A-Fa-f_]+", target):
            raise ConnectivityError("Invalid Bluetooth device")
        dev = _props(objects.get(target, {}), "org.bluez.Device1")
        if dev.get("Adapter") != path or not (dev.get("Paired") or dev.get("Connected")):
            raise ConnectivityError("Device is no longer available")
        _call("call", service, target, "org.bluez.Device1", operation.title(), timeout=30)
    else:
        raise ConnectivityError("Unsupported action")
