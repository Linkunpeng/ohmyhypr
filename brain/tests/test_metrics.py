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
            self.assertEqual(metrics.memory_usage(path)[0], 25)

    def test_temperature_uses_cpu_sensor_not_gpu(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for index, name, value in [(0, 'amdgpu', 90000), (1, 'k10temp', 47000)]:
                sensor = root / f'hwmon{index}'
                sensor.mkdir()
                (sensor / 'name').write_text(name)
                (sensor / 'temp1_input').write_text(str(value))
            self.assertEqual(metrics.cpu_temperature(root), 47)

    def test_memory_usage_reports_gib(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / 'meminfo'
            path.write_text('MemTotal: 16777216 kB\nMemAvailable: 12582912 kB\n')
            self.assertEqual(metrics.memory_usage(path), (25, 4.0))

    def test_default_interface_prefers_lowest_metric(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / 'route'
            path.write_text('Iface\tDestination\tGateway\tFlags\tRefCnt\tUse\tMetric\n'
                            'wlan0\t00000000\t0101A8C0\t0003\t0\t0\t600\n'
                            'eth0\t00000000\t0101A8C0\t0003\t0\t0\t100\n'
                            'wg0\t0000000A\t00000000\t0001\t0\t0\t0\n')
            self.assertEqual(metrics.default_interface(path), 'eth0')

    def test_net_rates_per_second_and_counter_reset(self):
        self.assertEqual(metrics.net_rates((1000, 5000), (3000, 9000), 2), (1000, 2000))
        self.assertIsNone(metrics.net_rates((3000, 9000), (10, 10), 1))
        self.assertIsNone(metrics.net_rates(None, (10, 10), 1))

    def test_gpu_selects_largest_vram_and_handles_missing_busy(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for card, total, used, busy in [('card0', 200, 100, '9'), ('card1', 1600, 400, '73')]:
                device = root / card / 'device'
                device.mkdir(parents=True)
                (device / 'mem_info_vram_total').write_text(str(total))
                (device / 'mem_info_vram_used').write_text(str(used))
                (device / 'gpu_busy_percent').write_text(busy)
            self.assertEqual(metrics.gpu_usage(root), (73, 25))
            (root / 'card1/device/gpu_busy_percent').unlink()
            self.assertEqual(metrics.gpu_usage(root), (None, 25))
            (root / 'card1/device/mem_info_vram_used').unlink()
            self.assertEqual(metrics.gpu_usage(root), (None, None))


if __name__ == '__main__':
    unittest.main()
