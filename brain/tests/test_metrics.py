import tempfile
import unittest
from pathlib import Path

from ohmyhypr import metrics


class MetricsTests(unittest.TestCase):
    def test_cpu_excludes_idle_and_handles_counter_resets(self):
        self.assertEqual(metrics.cpu_percent((100, 60), (200, 90)), 70)
        self.assertIsNone(metrics.cpu_percent((200, 90), (100, 60)))
        self.assertIsNone(metrics.cpu_percent(None, (100, 60)))

    def test_cpu_does_not_count_guest_twice(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / 'stat'
            path.write_text('cpu 100 0 20 200 5 0 0 0 80 0\ncpu0 0\n')
            self.assertEqual(metrics.cpu_times(path), (325, 205))

    def test_memory_uses_available_memory(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / 'meminfo'
            path.write_text('MemTotal: 1000 kB\nMemFree: 10 kB\nMemAvailable: 750 kB\n')
            self.assertEqual(metrics.memory_percent(path), 25)

    def test_temperature_uses_cpu_sensor_not_gpu(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for index, name, value in [(0, 'amdgpu', 90000), (1, 'k10temp', 47000)]:
                sensor = root / f'hwmon{index}'
                sensor.mkdir()
                (sensor / 'name').write_text(name)
                (sensor / 'temp1_input').write_text(str(value))
            self.assertEqual(metrics.cpu_temperature(root), 47)

    def test_muted_volume_keeps_stored_percentage(self):
        self.assertEqual(metrics.parse_volume('Volume: 0.40 [MUTED]'), (40, True))
        self.assertEqual(metrics.parse_volume('Volume: 1.25'), (125, False))
        self.assertEqual(metrics.parse_volume('no sink'), (None, False))


if __name__ == '__main__':
    unittest.main()
