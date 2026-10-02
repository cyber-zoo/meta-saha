#!/usr/bin/env python3
"""Check release selection and the offline lock consumed by BitBake."""

import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch


sys.dont_write_bytecode = True
script = Path(__file__).resolve().parents[1] / "scripts/resolve-microduck-release.py"
spec = importlib.util.spec_from_file_location("release_resolver", script)
resolver = importlib.util.module_from_spec(spec)
spec.loader.exec_module(resolver)


def release(tag, *, prerelease=False, digest="a" * 64):
    version = tag.removeprefix("daemon-v")
    return {"tag_name": tag, "draft": False, "prerelease": prerelease,
            "assets": [{"name": f"daemon-{version}.tar.zst", "digest": f"sha256:{digest}",
                        "browser_download_url":
                        f"https://github.com/pollen-robotics/microduck/releases/download/{tag}/daemon-{version}.tar.zst"}]}


class ReleaseResolverTest(unittest.TestCase):
    def test_latest_ignores_development_and_other_release_series(self):
        releases = [release("daemon-v0.16.0", prerelease=True), release("gst-v3.0.0"),
                    release("daemon-v0.15.1"), release("daemon-v0.14.9")]
        with patch.object(resolver, "fetch_json", return_value=releases):
            self.assertEqual(resolver.find_release("latest")["tag_name"], "daemon-v0.15.1")

    def test_release_asset_requires_digest_and_matching_url(self):
        candidate = release("daemon-v0.15.1")
        with patch.object(resolver, "tag_revision", return_value="1" * 40):
            lock = resolver.resolve_release(candidate)
        self.assertEqual(lock["version"], "0.15.1")
        self.assertEqual(lock["source_revision"], "1" * 40)
        candidate["assets"][0]["digest"] = ""
        with self.assertRaisesRegex(ValueError, "lacks an asset SHA256"):
            resolver.resolve_release(candidate)
        candidate["assets"][0]["digest"] = "sha256:" + "a" * 64
        candidate["assets"][0]["browser_download_url"] += ".wrong"
        with patch.object(resolver, "tag_revision", return_value="1" * 40):
            with self.assertRaisesRegex(ValueError, "archive URL"):
                resolver.resolve_release(candidate)

    def test_frozen_lock_writes_bitbake_values_without_fetching(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            lock = {"schema": 1, "repository": resolver.REPO, "tag": "daemon-v0.15.1",
                    "version": "0.15.1", "source_revision": "1" * 40,
                    "archive_sha256": "a" * 64,
                    "archive_url": "https://github.com/pollen-robotics/microduck/releases/download/"
                                   "daemon-v0.15.1/daemon-0.15.1.tar.zst"}
            archived = resolver.write_build_lock(directory, lock)
            self.assertEqual(json.loads((directory / "microduck-release.lock.json").read_text()), lock)
            self.assertEqual(json.loads(archived.read_text()), lock)
            inc = (directory / "microduck-release.inc").read_text()
            self.assertIn('MICRODUCK_VERSION = "0.15.1"', inc)
            self.assertIn(f'MICRODUCK_SRCREV = "{"1" * 40}"', inc)
            lock["archive_sha256"] = "bad"
            with self.assertRaisesRegex(ValueError, "SHA256"):
                resolver.write_build_lock(directory, lock)


if __name__ == "__main__":
    unittest.main()
