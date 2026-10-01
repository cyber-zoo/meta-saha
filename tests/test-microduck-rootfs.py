#!/usr/bin/env python3
"""Protect extracted-image inspection from host symlink interpretation."""
import importlib.util
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


if __name__ == "__main__":
    unittest.main()
