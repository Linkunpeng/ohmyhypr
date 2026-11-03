"""Exercise provider wire formats without contacting a model service."""

import contextlib
import io
import json
import os
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from unittest.mock import patch

from ohmyhypr import cli, config, providers


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        self.server.requests.append((self.path, dict(self.headers), json.loads(self.rfile.read(int(self.headers["Content-Length"])))))
        self.send_response(self.server.status)
        self.end_headers()
        self.wfile.write(self.server.response)

    def log_message(self, *_args):
        pass


class ProviderTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.thread.join()
        cls.server.server_close()

    def setUp(self):
        self.server.requests = []
        self.server.status = 200
        self.url = f"http://127.0.0.1:{self.server.server_port}/v1"
        self.cfg = {"ai": {"default_provider": "test"}, "providers": {"test": {
            "type": "openai", "base_url": self.url, "model": "example", "api_key_env": "TEST_OMH_KEY"
        }}}
        self.messages = [{"role": "system", "content": "system"}, {"role": "user", "content": "你好"}]

    def test_openai_stream_and_authorization(self):
        self.server.response = (b'data: {"choices":[{"delta":{"content":"hello"}}]}\n\n'
                                b'data: {"choices":[]}\n\n'
                                b'data: {"choices":[{"delta":{"content":"!"}}]}\n\n'
                                b'data: [DONE]\n\n')
        with patch.dict(os.environ, {"TEST_OMH_KEY": "secret"}):
            self.assertEqual("".join(providers.chat(self.cfg, self.messages)), "hello!")
        path, headers, body = self.server.requests[0]
        self.assertEqual(path, "/v1/chat/completions")
        self.assertEqual(headers["Authorization"], "Bearer secret")
        self.assertEqual(body, {"model": "example", "stream": True, "messages": self.messages})

    def test_anthropic_stream_and_system_message(self):
        self.cfg["providers"]["test"].update(type="anthropic", max_tokens=42)
        self.server.response = (b'event: content_block_delta\n'
                                b'data: {"type":"content_block_delta",\n'
                                b'data: "delta":{"type":"text_delta","text":"ok"}}\n\n'
                                b'data: {"type":"message_stop"}\n\n')
        with patch.dict(os.environ, {"TEST_OMH_KEY": "secret"}):
            self.assertEqual("".join(providers.chat(self.cfg, self.messages)), "ok")
        path, headers, body = self.server.requests[0]
        self.assertEqual(path, "/v1/messages")
        self.assertEqual(headers["X-Api-Key"], "secret")
        self.assertEqual(headers["Anthropic-Version"], "2023-06-01")
        self.assertEqual(body, {"model": "example", "stream": True, "max_tokens": 42,
                                "system": "system", "messages": self.messages[1:]})

    def test_missing_key_does_not_send_request(self):
        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaisesRegex(providers.ProviderError, "TEST_OMH_KEY"):
                list(providers.chat(self.cfg, self.messages))
        self.assertEqual(self.server.requests, [])

    def test_no_key_for_compatible_server(self):
        del self.cfg["providers"]["test"]["api_key_env"]
        self.server.response = b'data: {"choices":[{"delta":{"content":"ok"}}]}\n\n'
        self.assertEqual("".join(providers.chat(self.cfg, self.messages)), "ok")
        self.assertNotIn("Authorization", self.server.requests[0][1])

    def test_http_errors_do_not_expose_response_or_key(self):
        self.server.status = 401
        self.server.response = b'sensitive response'
        with patch.dict(os.environ, {"TEST_OMH_KEY": "secret"}):
            with self.assertRaises(providers.ProviderError) as result:
                list(providers.chat(self.cfg, self.messages))
        self.assertIn("HTTP 401", str(result.exception))
        self.assertNotIn("secret", str(result.exception))
        self.assertNotIn("sensitive response", str(result.exception))

    def test_default_context_off_and_explicit_on(self):
        with patch.object(config, "load", return_value={"ai": {"default_provider": "test", "include_context": False}}), \
             patch.object(cli.context, "snapshot", return_value={"clipboard": "sensitive"}) as snapshot, \
             contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(cli.main(["ask", "--dry-run", "question"]), 0)
            snapshot.assert_not_called()
            self.assertNotIn("sensitive", out.getvalue())
            out.seek(0)
            out.truncate()
            self.assertEqual(cli.main(["ask", "--dry-run", "--context", "question"]), 0)
            snapshot.assert_called_once()
            self.assertIn("sensitive", out.getvalue())

    def test_no_context_overrides_config(self):
        with patch.object(config, "load", return_value={"ai": {"default_provider": "test", "include_context": True}}), \
             patch.object(cli.context, "snapshot") as snapshot, \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(cli.main(["ask", "--dry-run", "--no-context", "question"]), 0)
            snapshot.assert_not_called()


if __name__ == "__main__":
    unittest.main()
