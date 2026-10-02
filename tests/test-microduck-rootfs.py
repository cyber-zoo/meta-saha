#!/usr/bin/env python3
"""Protect extracted-image inspection from host symlink interpretation."""
import importlib.util
import json
from pathlib import Path
import tempfile
import sys
import unittest

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("rootfs", Path(__file__).with_name("check-microduck-rootfs.py"))
rootfs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rootfs)


class ImagePathTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "usr/bin").mkdir(parents=True)
        (self.root / "opt/robot").mkdir(parents=True)
        (self.root / "opt/robot/robotctl").write_text("target")

    def test_absolute_link_stays_in_image(self):
        (self.root / "usr/bin/robotctl").symlink_to("/opt/robot/robotctl")
        self.assertEqual(rootfs.image_path(self.root, "/usr/bin/robotctl"), self.root / "opt/robot/robotctl")

    def test_relative_usrmerge_link(self):
        (self.root / "bin").symlink_to("usr/bin")
        (self.root / "usr/bin/robotctl").symlink_to("../../opt/robot/robotctl")
        self.assertEqual(rootfs.image_path(self.root, "/bin/robotctl"), self.root / "opt/robot/robotctl")

    def test_parent_at_chroot_boundary_stays_in_image(self):
        (self.root / "usr/bin/robotctl").symlink_to("../../../../opt/robot/robotctl")
        self.assertEqual(rootfs.image_path(self.root, "/usr/bin/robotctl"), self.root / "opt/robot/robotctl")

    def test_loop_is_rejected(self):
        (self.root / "usr/bin/robotctl").symlink_to("robotctl")
        with self.assertRaisesRegex(ValueError, "symlink loop"):
            rootfs.image_path(self.root, "/usr/bin/robotctl")


class RuntimeIdentityTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "image"
        release = self.root / "opt/robot/daemon/releases/0.15.1"
        release.mkdir(parents=True)
        (release / "version.toml").write_text('version = "0.15.1"\nrevision = "' + "1" * 40 + '"\n')
        (self.root / "opt/robot/daemon/current").symlink_to("releases/0.15.1")
        self.source = self.root / "usr/share/saha/microduck/runtime-source"
        self.source.parent.mkdir(parents=True)
        self.source.write_text("version=0.15.1\nrevision=" + "1" * 40 + "\narchive_sha256=" + "a" * 64 + "\n")
        self.lock = Path(self.temp.name) / "release.lock.json"
        self.lock.write_text(json.dumps({"tag": "daemon-v0.15.1", "version": "0.15.1",
                                         "source_revision": "1" * 40, "archive_sha256": "a" * 64}))

    def test_image_matches_release_lock(self):
        version, revision, archive_sha = rootfs.verify_runtime_identity(self.root, self.lock)
        self.assertEqual((version["version"], revision, archive_sha), ("0.15.1", "1" * 40, "a" * 64))

    def test_changed_archive_provenance_fails(self):
        self.source.write_text(self.source.read_text().replace("a" * 64, "b" * 64))
        with self.assertRaisesRegex(ValueError, "provenance differs"):
            rootfs.verify_runtime_identity(self.root, self.lock)


if __name__ == "__main__":
    unittest.main()
