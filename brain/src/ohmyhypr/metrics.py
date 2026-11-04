"""Local system counters for the bar; no window, clipboard or application data."""
from __future__ import annotations

import json
import os
import time
from pathlib import Path


def cpu_times(path: Path = Path('/proc/stat')) -> tuple[int, int] | None:
    try:
        fields = path.read_text().splitlines()[0].split()
        values = [int(v) for v in fields[1:9]]  # Guest time is already included in user/nice.
        return sum(values), values[3] + values[4]
    except (OSError, ValueError, IndexError):
        return None


def cpu_percent(previous, current) -> int | None:
    if not previous or not current or current[0] <= previous[0]:
        return None
    total = current[0] - previous[0]
    idle = current[1] - previous[1]
    return round(max(0, min(100, 100 * (total - idle) / total)))


def memory_usage(path: Path = Path('/proc/meminfo')) -> tuple[int, float] | None:
    """Used memory as (percent, GiB)."""
    try:
        values = {line.split(':')[0]: int(line.split()[1]) for line in path.read_text().splitlines()}
        available = values.get('MemAvailable', sum(values.get(k, 0) for k in ('MemFree', 'Buffers', 'Cached')))
        used = values['MemTotal'] - available
        return round(max(0, min(100, 100 * used / values['MemTotal']))), round(used / 1024 ** 2, 1)
    except (OSError, ValueError, KeyError, ZeroDivisionError):
        return None


def disk_percent(path: str = '/') -> int | None:
    try:
        stats = os.statvfs(path)
        return round(100 - 100 * stats.f_bavail / stats.f_blocks)
    except (OSError, ZeroDivisionError):
        return None


def default_interface(path: Path = Path('/proc/net/route')) -> str | None:
    """Interface of the lowest-metric default route."""
    try:
        routes = [line.split() for line in path.read_text().splitlines()[1:]]
        defaults = [(int(r[6]), r[0]) for r in routes if len(r) > 6 and r[1] == '00000000']
        return min(defaults)[1] if defaults else None
    except (OSError, ValueError):
        return None


def net_counters(iface: str | None, root: Path = Path('/sys/class/net')) -> tuple[int, int] | None:
    if not iface:
        return None
    try:
        stats = root / iface / 'statistics'
        return int((stats / 'tx_bytes').read_text()), int((stats / 'rx_bytes').read_text())
    except (OSError, ValueError):
        return None


def net_rates(previous, current, seconds: float) -> tuple[int, int] | None:
    """Upload and download bytes per second; None across counter resets."""
    if not previous or not current or seconds <= 0 or current[0] < previous[0] or current[1] < previous[1]:
        return None
    return round((current[0] - previous[0]) / seconds), round((current[1] - previous[1]) / seconds)


def cpu_temperature(root: Path = Path('/sys/class/hwmon')) -> int | None:
    readings = []
    for sensor in root.glob('hwmon*'):
        try:
            name = (sensor / 'name').read_text().strip().lower()
        except OSError:
            continue
        if name not in {'k10temp', 'coretemp', 'zenpower', 'cpu_thermal', 'cpu-thermal'}:
            continue
        for path in sensor.glob('temp*_input'):
            try:
                value = int(path.read_text()) / 1000
                if -20 <= value <= 150:
                    readings.append(value)
            except (OSError, ValueError):
                continue
    return round(max(readings)) if readings else None


def gpu_usage(root: Path = Path('/sys/class/drm')) -> tuple[int | None, int | None] | None:
    """AMD GPU utilization and VRAM percent, preferring the largest VRAM pool."""
    devices = []
    for card in root.glob('card[0-9]*'):
        if not card.name[4:].isdigit():
            continue
        device = card / 'device'
        try:
            total = int((device / 'mem_info_vram_total').read_text())
            if total <= 0:
                continue
        except (OSError, ValueError):
            continue
        devices.append((total, card.name, device))
    if not devices:
        return None
    total, _, device = max(devices, key=lambda item: (item[0], item[1]))
    try:
        busy = max(0, min(100, int((device / 'gpu_busy_percent').read_text())))
    except (OSError, ValueError):
        busy = None
    try:
        used = int((device / 'mem_info_vram_used').read_text())
        vram = round(max(0, min(100, 100 * used / total)))
    except (OSError, ValueError):
        vram = None
    return busy, vram


def run(watch: bool = False) -> int:
    previous = cpu_times()
    iface = default_interface()
    traffic, stamp = net_counters(iface), time.monotonic()
    try:
        while True:
            time.sleep(1 if watch else 0.2)
            current = cpu_times()
            memory = memory_usage()
            gpu = gpu_usage()
            now, current_iface = time.monotonic(), default_interface()
            counters = net_counters(current_iface)
            rates = net_rates(traffic, counters, now - stamp) if current_iface == iface else None
            net = {'iface': current_iface, 'wireless': (Path('/sys/class/net') / current_iface / 'wireless').exists(),
                   'up': rates[0] if rates else 0, 'down': rates[1] if rates else 0} if current_iface else None
            print(json.dumps({'cpu': cpu_percent(previous, current), 'memory': memory[0] if memory else None,
                              'memory_gib': memory[1] if memory else None, 'disk': disk_percent(),
                              'temperature': cpu_temperature(), 'net': net,
                              'gpu': gpu[0] if gpu else None, 'vram': gpu[1] if gpu else None}), flush=True)
            previous, iface, traffic, stamp = current, current_iface, counters, now
            if not watch:
                return 0
    except BrokenPipeError:
        return 0
