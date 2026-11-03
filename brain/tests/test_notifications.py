"""Exercise the notification service on an isolated D-Bus session."""

import os
import shutil
import subprocess
import sys
import unittest
from pathlib import Path


SCRIPT = r'''
import json, os, pathlib, shutil, subprocess, sys, tempfile, time
source = pathlib.Path(sys.argv[1])
nested = sys.argv[2] == "nested"
with tempfile.TemporaryDirectory(prefix="omh-notify-test-") as temporary:
    root = pathlib.Path(temporary)
    (root / "services").mkdir()
    shutil.copy2(source, root / "services/NotificationStore.qml")
    (root / "services/qmldir").write_text("singleton NotificationStore 1.0 NotificationStore.qml\n")
    (root / "shell.qml").write_text('import QtQuick\nimport Quickshell\nimport "services"\nShellRoot { property var store: NotificationStore }\n')
    runtime = root / "runtime"
    runtime.mkdir(mode=0o700)
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
               XDG_RUNTIME_DIR=str(runtime), WAYLAND_DISPLAY="")
    if nested:
        env["OHMYHYPR_NESTED"] = "1"
    else:
        env.pop("OHMYHYPR_NESTED", None)
    shell = subprocess.Popen(["qs", "-p", str(root)], env=env, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, text=True)
    try:
        for _ in range(50):
            if shell.poll() is not None:
                raise RuntimeError("notification shell exited: " + shell.stdout.read())
            result = subprocess.run(["qs", "ipc", "-p", str(root), "show"], env=env,
                                    capture_output=True, text=True)
            if "target notifications" in result.stdout:
                break
            time.sleep(0.1)
        else:
            raise RuntimeError("notification IPC not ready: " + result.stderr)
        command = ["qs", "ipc", "-p", str(root), "call", "notifications"]
        if nested:
            names = subprocess.check_output(["busctl", "--user", "list"], env=env, text=True)
            assert "org.freedesktop.Notifications" not in names
        else:
            first = subprocess.check_output(["notify-send", "-p", "-a", "omh-test", "First", "Body"], env=env, text=True).strip()
            subprocess.check_output(["notify-send", "-p", "-a", "omh-test", "Second", "Body"], env=env, text=True)
            status = json.loads(subprocess.check_output(command + ["status"], env=env, text=True))
            assert status["notifications"] == 2 and status["notificationPreview"] == "Second", status
            subprocess.run(command + ["removeNotification", first], env=env, check=True)
            status = json.loads(subprocess.check_output(command + ["status"], env=env, text=True))
            assert status["notifications"] == 1, status
            subprocess.run(command + ["clearNotifications"], env=env, check=True)
            status = json.loads(subprocess.check_output(command + ["status"], env=env, text=True))
            assert status["notifications"] == 0, status
    finally:
        shell.terminate()
        try:
            shell.wait(timeout=3)
        except subprocess.TimeoutExpired:
            shell.kill()
            shell.wait()
'''


@unittest.skipUnless(all(shutil.which(c) for c in ("qs", "dbus-run-session", "notify-send", "busctl")),
                     "Quickshell, D-Bus tools and notify-send are required")
class NotificationTests(unittest.TestCase):
    def run_service(self, mode):
        source = Path(__file__).resolve().parents[2] / "shell/services/NotificationStore.qml"
        result = subprocess.run(["dbus-run-session", "--", sys.executable, "-c", SCRIPT, str(source), mode],
                                timeout=15, capture_output=True, text=True, env=os.environ.copy())
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_receive_remove_and_clear(self):
        self.run_service("normal")

    def test_nested_session_does_not_claim_notifications(self):
        self.run_service("nested")
