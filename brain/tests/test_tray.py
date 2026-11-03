"""Recover active tray items without duplicating existing registrations."""

import unittest
from unittest.mock import patch

from ohmyhypr import tray


class TrayRecoveryTests(unittest.TestCase):
    def test_recovers_active_items_only_once(self):
        names = [
            {"name": "org.kde.StatusNotifierItem-10-1", "connection": ":1.10"},
            {"name": "org.kde.StatusNotifierItem-11-1", "connection": ":1.11"},
            {"name": "org.kde.StatusNotifierItem-12-1", "connection": ":1.12"},
            {"name": "unrelated.service", "connection": ":1.13"},
        ]
        calls = []

        def fake_bus(*args):
            calls.append(args)
            if args == ("list",):
                return names
            if args[-1] == "RegisteredStatusNotifierItems":
                return {"data": [":1.10/StatusNotifierItem"]}
            if args[-1] == "Status":
                return {"data": "Passive" if args[1].endswith("12-1") else "Active"}
            if args[0] == "call":
                return None
            self.fail(f"unexpected D-Bus request: {args!r}")

        with patch.object(tray, "_bus", side_effect=fake_bus):
            self.assertEqual(tray.recover(), 1)
        registered = [call[-1] for call in calls if call[0] == "call"]
        self.assertEqual(registered, ["org.kde.StatusNotifierItem-11-1"])

    def test_absent_watcher_is_harmless(self):
        with patch.object(tray, "_bus", side_effect=OSError("unavailable")):
            self.assertEqual(tray.recover(), 0)


if __name__ == "__main__":
    unittest.main()
