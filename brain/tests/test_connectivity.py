"""Wi-Fi and Bluetooth menu data without changing radio state."""

import json
import unittest
from unittest.mock import patch

from ohmyhypr import connectivity


def props(**values):
    return {key: {"data": value} for key, value in values.items()}


WIFI_PATH = "/net/connman/iwd/0/4"
NETWORK_PATH = WIFI_PATH + "/network_psk"
BT_PATH = "/org/bluez/hci0"
BT_DEVICE = BT_PATH + "/dev_01_23_45_67_89_AB"


class ConnectivityTests(unittest.TestCase):
    def setUp(self):
        self.iwd = {
            WIFI_PATH: {"net.connman.iwd.Device": props(Name="wlan0", Powered=True),
                        "net.connman.iwd.Station": props(State="connected")},
            NETWORK_PATH: {"net.connman.iwd.Network": props(Name="Home WiFi", Type="psk", Device=WIFI_PATH, Connected=True)},
            "/known": {"net.connman.iwd.KnownNetwork": props(Name="Home WiFi", Type="psk")},
        }
        self.bluez = {
            BT_PATH: {"org.bluez.Adapter1": props(Powered=True)},
            BT_DEVICE: {"org.bluez.Device1": props(Adapter=BT_PATH, Alias="Headphones", Address="01:23:45:67:89:AB", Paired=True, Connected=True)},
        }

    def objects(self, service):
        return self.iwd if service == "net.connman.iwd" else self.bluez

    def test_snapshot_reports_connected_and_saved_devices(self):
        ordered = json.dumps({"data": [[[NETWORK_PATH, -5500]]]})
        with patch.object(connectivity, "_objects", side_effect=self.objects), patch.object(connectivity, "_call", return_value=ordered):
            result = connectivity.snapshot()
        self.assertEqual(result["wifi"]["interface"], "wlan0")
        self.assertEqual(result["wifi"]["connected"], "Home WiFi")
        self.assertTrue(result["wifi"]["networks"][0]["known"])
        self.assertEqual(result["wifi"]["networks"][0]["signal"], -55)
        self.assertTrue(result["bluetooth"]["devices"][0]["connected"])

    def test_unavailable_services_are_reported(self):
        with patch.object(connectivity, "_objects", return_value=None):
            result = connectivity.snapshot()
        self.assertFalse(result["wifi"]["available"])
        self.assertFalse(result["bluetooth"]["available"])

    def test_power_action_uses_discovered_adapter(self):
        with patch.object(connectivity, "_objects", side_effect=self.objects), patch.object(connectivity, "_call") as call:
            connectivity.action("wifi", "off")
        call.assert_called_once_with("set-property", "net.connman.iwd", WIFI_PATH, "net.connman.iwd.Device", "Powered", "b", "false")

    def test_rejects_untrusted_or_missing_targets(self):
        with patch.object(connectivity, "_objects", side_effect=self.objects), patch.object(connectivity, "_call") as call:
            with self.assertRaises(connectivity.ConnectivityError):
                connectivity.action("wifi", "connect", "/invalid")
            with self.assertRaises(connectivity.ConnectivityError):
                connectivity.action("bluetooth", "connect", "/org/bluez/hci0/invalid")
        call.assert_not_called()

    def test_connects_only_paired_bluetooth_devices(self):
        with patch.object(connectivity, "_objects", side_effect=self.objects), patch.object(connectivity, "_call") as call:
            connectivity.action("bluetooth", "disconnect", BT_DEVICE)
        call.assert_called_once_with("call", "org.bluez", BT_DEVICE, "org.bluez.Device1", "Disconnect", timeout=30)


if __name__ == "__main__":
    unittest.main()
