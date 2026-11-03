"""Contract tests for the external avatar adapter client."""

import contextlib
import io
import json
import socketserver
import tempfile
import threading
import unittest
from pathlib import Path
from unittest.mock import patch

from ohmyhypr import cli, config
from ohmyhypr.avatar import client


class Handler(socketserver.StreamRequestHandler):
    def handle(self):
        request = json.loads(self.rfile.readline())
        self.server.requests.append(request)
        reply = {"ok": True}
        if request["cmd"] == "persona":
            reply["persona"] = "character persona"
        if request["cmd"] == "motion":
            reply["supported"] = False
        self.wfile.write((json.dumps(reply) + "\n").encode())


class AvatarTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.server = socketserver.UnixStreamServer(str(Path(self.tmp.name) / "avatar.sock"), Handler)
        self.server.requests = []
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.cfg = {"avatar": {"socket": self.server.server_address, "command": [], "model": ""},
                    "ai": {"default_provider": "test", "include_context": False}}

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()
        self.tmp.cleanup()

    def test_load_unload_persona_and_missing_action(self):
        with patch.object(config, "load", return_value=self.cfg), contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(cli.main(["avatar", "load", "sample"]), 0)
            self.assertEqual(cli.main(["avatar", "persona"]), 0)
            self.assertEqual(cli.main(["avatar", "motion", "notify_3"]), 0)
            self.assertEqual(cli.main(["avatar", "unload"]), 0)
        self.assertEqual(out.getvalue(), "character persona\n")
        self.assertEqual(self.server.requests, [{"cmd": "load", "model": "sample"}, {"cmd": "persona"},
                                                {"cmd": "motion", "name": "notify_3"}, {"cmd": "unload"}])

    def test_chat_uses_persona_and_configured_provider(self):
        with patch.object(config, "load", return_value=self.cfg), \
             patch("ohmyhypr.avatar.cli.providers.chat", return_value=iter(["hello", " world"])) as chat, \
             patch("ohmyhypr.avatar.cli.context.snapshot") as snapshot:
            self.assertEqual(cli.main(["avatar", "ask", "question"]), 0)
        snapshot.assert_not_called()
        self.assertEqual(chat.call_args.args[1], [{"role": "system", "content": "character persona"},
                                                   {"role": "user", "content": "question"}])
        self.assertEqual(self.server.requests, [{"cmd": "persona"}, {"cmd": "thinking", "on": True},
                                                {"cmd": "stream", "chunk": "hello"},
                                                {"cmd": "stream", "chunk": " world"},
                                                {"cmd": "thinking", "on": False}, {"cmd": "stream_end"}])

    def test_absent_adapter_reports_error(self):
        self.cfg["avatar"]["socket"] = str(Path(self.tmp.name) / "missing.sock")
        with self.assertRaises(client.AvatarError):
            client.send(self.cfg, {"cmd": "status"})

    def test_start_passes_socket_and_model_to_configured_adapter(self):
        self.cfg["avatar"].update(command=["/some/adapter", "--option"], model="example")
        with patch.object(config, "load", return_value=self.cfg), \
             patch("ohmyhypr.avatar.cli.client.send", side_effect=client.AvatarError("not running")), \
             patch("ohmyhypr.avatar.cli.paths.STATE", Path(self.tmp.name)), \
             patch("ohmyhypr.avatar.cli.subprocess.Popen") as spawn, \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(cli.main(["avatar", "run", "--detach"]), 0)
        self.assertEqual(spawn.call_args.args[0], ["/some/adapter", "--option"])
        self.assertEqual(spawn.call_args.kwargs["env"]["AVATAR_MODEL"], "example")
        self.assertEqual(spawn.call_args.kwargs["env"]["AVATAR_SOCKET"], self.server.server_address)


if __name__ == "__main__":
    unittest.main()
