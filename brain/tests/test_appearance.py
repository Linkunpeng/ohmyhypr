"""Wallpaper, color, and lock policy tests without touching the live session."""

import json
import shutil
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from ohmyhypr import lockscreen, palette, paths, theme, wallpaper


def rgb(value):
    return tuple(int(value[i:i + 2], 16) for i in (1, 3, 5))


class PaletteTests(unittest.TestCase):
    def test_generated_colors_have_readable_contrast(self):
        pixels = bytes([220, 50, 30] * 400 + [25, 100, 190] * 100 + [210, 210, 210] * 100)
        for dark in (True, False):
            colors = palette.from_pixels(pixels, dark)
            for key in ("fg", "muted", "accent", "accent_alt", "urgent"):
                self.assertGreaterEqual(palette.contrast(rgb(colors[key]), rgb(colors["surface"])), 4.49, key)
            self.assertEqual(colors["border_active"], colors["accent"])

    def test_invalid_pixels_fail(self):
        with self.assertRaises(palette.PaletteError):
            palette.from_pixels(b'')

    def test_bar_opacity_adapts_to_wallpaper_contrast(self):
        bright = palette.from_pixels(bytes([248, 248, 248] * 100), dark=True)
        dark = palette.from_pixels(bytes([8, 8, 8] * 100), dark=True)
        self.assertEqual(dark["bar_opacity"], 0.38)
        self.assertGreater(bright["bar_opacity"], dark["bar_opacity"])
        background = palette._mix((248, 248, 248), rgb(bright["bg"]), bright["bar_opacity"])
        self.assertGreaterEqual(palette.contrast(rgb(bright["fg"]), background), 4.5)

        light_theme = palette.from_pixels(bytes([8, 8, 8] * 100), dark=False)
        background = palette._mix((8, 8, 8), rgb(light_theme["bg"]), light_theme["bar_opacity"])
        self.assertGreaterEqual(palette.contrast(rgb(light_theme["fg"]), background), 4.5)


class AppearanceTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.patches = [patch.object(paths, "STATE", root), patch.object(paths, "THEME_JSON", root / "theme.json"),
                        patch.object(paths, "THEME_LUA", root / "theme.lua"),
                        patch.object(paths, "PALETTE_JSON", root / "palette.json"),
                        patch.object(theme, "in_ohmyhypr_session", return_value=False)]
        for item in self.patches:
            item.start()
        self.image = root / "wall #1.ppm"
        self.image.write_bytes(b"P6\n4 4\n255\n" + bytes([220, 40, 30] * 12 + [20, 100, 180] * 4))

    def tearDown(self):
        for item in reversed(self.patches):
            item.stop()
        self.tmp.cleanup()

    @unittest.skipUnless(shutil.which("ffmpeg"), "ffmpeg required")
    def test_wallpaper_changes_shared_palette_and_preserves_shape(self):
        self.assertEqual(theme.apply("midnight")["theme"], "midnight")
        before = theme.current()
        report = wallpaper.set_wallpaper(self.image.as_uri())
        after = theme.current()
        standalone = palette.current()
        self.assertEqual(report["wallpaper"], str(self.image))
        self.assertEqual(after["wallpaper"]["path"], str(self.image))
        self.assertEqual(after["shape"], before["shape"])
        self.assertEqual(after["palette_source"], "wallpaper")
        self.assertEqual(standalone["colors"], after["palette"])
        self.assertEqual(standalone["rev"], after["rev"])
        self.assertIn(after["palette"]["accent"][1:] + "ff", paths.THEME_LUA.read_text())

    def test_lock_uses_blurred_desktop_background(self):
        config = lockscreen.lock_config()
        self.assertIn("path = screenshot", config)
        self.assertIn("blur_passes = 3", config)
        self.assertIn("blur_size = 8", config)

    def test_failed_extraction_preserves_existing_state(self):
        theme.apply("midnight")
        old = {p: p.read_bytes() for p in (paths.THEME_JSON, paths.THEME_LUA, paths.PALETTE_JSON)}
        with patch.object(palette, "extract", side_effect=palette.PaletteError("bad image")):
            with self.assertRaises(wallpaper.WallpaperError):
                wallpaper.set_wallpaper(str(self.image))
        self.assertEqual(old, {p: p.read_bytes() for p in old})

    def test_palette_can_be_applied_without_changing_wallpaper_or_shape(self):
        theme.apply("midnight")
        before = theme.current()
        colors = palette.from_pixels(bytes([30, 170, 60] * 30))
        file = paths.STATE / "colors.json"
        file.write_text(json.dumps(colors))
        palette.apply_file(file)
        after = theme.current()
        self.assertEqual(after["wallpaper"], before["wallpaper"])
        self.assertEqual(after["shape"], before["shape"])
        self.assertEqual(after["palette"]["accent"], colors["accent"])
        self.assertEqual(after["palette"]["bar_opacity"], colors["bar_opacity"])
        self.assertEqual(palette.current()["source"], "file")

    def test_bad_file_urls_are_rejected(self):
        with self.assertRaises(wallpaper.WallpaperError):
            wallpaper.image_path("file://other-host/tmp/image.png")

    def test_target_screen_keeps_other_screens_wallpaper(self):
        theme.apply("midnight")
        before = theme.current()["wallpaper"]
        colors = palette.from_pixels(bytes([20, 100, 180] * 20))
        with patch.object(wallpaper, "monitors", return_value=[{"name": "screen-a", "focused": True}, {"name": "screen-b"}]), \
             patch.object(palette, "extract", return_value=colors):
            wallpaper.set_wallpaper(str(self.image), screen="screen-a")
            state = theme.current()
            self.assertEqual(state["wallpaper"], before)
            self.assertEqual(state["wallpapers"]["screen-a"]["path"], str(self.image))
            self.assertNotIn("screen-b", state["wallpapers"])
            self.assertEqual(palette.current()["wallpaper"], str(self.image))
            with self.assertRaises(wallpaper.WallpaperError):
                wallpaper.set_wallpaper(str(self.image), screen="missing")

    def test_catalog_reads_configured_directory_and_encodes_urls(self):
        image = paths.STATE / "a # image.PNG"
        image.touch()
        (paths.STATE / "ignore.txt").touch()
        with patch.object(wallpaper, "monitors", return_value=[{"name": "screen-a", "focused": True}]):
            result = wallpaper.catalog({"wallpaper": {"directory": str(paths.STATE)}})
        self.assertEqual(result["screen"], "screen-a")
        self.assertEqual(len(result["items"]), 1)
        self.assertIn("%23", result["items"][0]["url"])

    def test_theme_palette_fallback_when_extraction_fails(self):
        resolved = theme.resolve("midnight")
        resolved["wallpaper"]["path"] = str(self.image)
        with patch.object(theme, "resolve", return_value=resolved), \
             patch.object(palette, "extract", side_effect=palette.PaletteError("ffmpeg unavailable")):
            result = theme.apply("midnight")
        self.assertIn("theme colors", result["warning"])
        self.assertEqual(json.loads(paths.PALETTE_JSON.read_text())["source"], "theme")


class LockTests(unittest.TestCase):
    def test_idle_policy_and_disable(self):
        cfg = lockscreen.idle_config({"lock": {"timeout_seconds": 300, "before_sleep": True}})
        self.assertIn("timeout = 300", cfg)
        self.assertIn("before_sleep_cmd = loginctl lock-session", cfg)
        self.assertIn("inhibit_sleep = 3", cfg)
        cfg = lockscreen.idle_config({"lock": {"timeout_seconds": 0, "before_sleep": False}})
        self.assertIn("on-timeout = true", cfg)
        self.assertNotIn("on-timeout = loginctl lock-session", cfg)
        self.assertNotIn("before_sleep_cmd", cfg)

    def test_invalid_timeout_rejected(self):
        with self.assertRaises(lockscreen.LockError):
            lockscreen.idle_config({"lock": {"timeout_seconds": -1}})


if __name__ == "__main__":
    unittest.main()
