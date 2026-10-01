#!/usr/bin/env python3
"""Reject corrupt or incompatible A733 legacy kernel headers."""
import importlib.util
from pathlib import Path
import struct
import sys
import unittest
import zlib

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("boot_check", Path(__file__).with_name("check-microduck-boot.py"))
boot = importlib.util.module_from_spec(spec)
spec.loader.exec_module(boot)


def image(arch=2, load=0x41000000):
    payload = b"test kernel payload"
    header = bytearray(struct.pack(
        ">7I4B32s", 0x27051956, 0, 0, len(payload), load, load,
        zlib.crc32(payload), 5, arch, 2, 0, b"test"))
    struct.pack_into(">I", header, 4, zlib.crc32(header))
    return bytes(header) + payload


class UimageTest(unittest.TestCase):
    def test_valid_vendor_header_returns_exact_payload(self):
        self.assertEqual(boot.check_uimage(image()), b"test kernel payload")

    def test_corrupt_payload_is_rejected(self):
        data = bytearray(image())
        data[-1] ^= 1
        with self.assertRaisesRegex(ValueError, "payload checksum"):
            boot.check_uimage(data)

    def test_corrupt_header_is_rejected(self):
        data = bytearray(image())
        data[16] ^= 1
        with self.assertRaisesRegex(ValueError, "header checksum"):
            boot.check_uimage(data)

    def test_arm64_header_is_incompatible_with_vendor_bootm(self):
        with self.assertRaisesRegex(ValueError, "Linux/ARM"):
            boot.check_uimage(image(arch=22))

    def test_wrong_load_address_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "load/entry"):
            boot.check_uimage(image(load=0x40000000))

    def test_truncation_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "truncated"):
            boot.check_uimage(image()[:63])


if __name__ == "__main__":
    unittest.main()
