"""Local system counters for the bar; no window, clipboard or application data."""
from __future__ import annotations

import json
import re
import subprocess
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


def memory_percent(path: Path = Path('/proc/meminfo')) -> int | None:
    try:
        values = {line.split(':')[0]: int(line.split()[1]) for line in path.read_text().splitlines()}
        available = values.get('MemAvailable', sum(values.get(k, 0) for k in ('MemFree', 'Buffers', 'Cached')))
        return round(max(0, min(100, 100 * (values['MemTotal'] - available) / values['MemTotal'])))
    except (OSError, ValueError, KeyError, ZeroDivisionError):
        return None


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


def parse_volume(text: str) -> tuple[int | None, bool]:
    match = re.search(r'Volume:\s*([0-9]+(?:\.[0-9]+)?)', text)
    return (round(float(match[1]) * 100), '[MUTED]' in text) if match else (None, False)


def volume() -> tuple[int | None, bool]:
    try:
        result = subprocess.run(['wpctl', 'get-volume', '@DEFAULT_AUDIO_SINK@'], capture_output=True,
                                text=True, timeout=1)
        return parse_volume(result.stdout) if result.returncode == 0 else (None, False)
    except (OSError, subprocess.TimeoutExpired):
        return None, False


def run(watch: bool = False) -> int:
    previous = cpu_times()
    try:
        while True:
            time.sleep(2 if watch else 0.2)
            current = cpu_times()
            level, muted = volume()
            print(json.dumps({'cpu': cpu_percent(previous, current), 'memory': memory_percent(),
                              'temperature': cpu_temperature(), 'volume': level, 'muted': muted}), flush=True)
            previous = current
            if not watch:
                return 0
    except BrokenPipeError:
        return 0
