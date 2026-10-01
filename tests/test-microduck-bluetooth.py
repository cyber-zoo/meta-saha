#!/usr/bin/env python3
"""Check radio selection, driver readiness and errors without a UART."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "saha-layers/meta-saha-microduck/recipes-robot/bluetooth/files/microduck-bluetooth-uart"


class BluetoothUartTest(unittest.TestCase):
    def run_init(self, vendor, bind_after=0, attach_status=0):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            radio = path / "sdio/mmc2:0001:1"
            radio.mkdir(parents=True)
            (radio / "vendor").write_text(vendor + "\n")
            if bind_after == 0:
                (radio / "driver").mkdir()
            (path / "hciattach").write_text("""#!/bin/sh
printf '%s\\n' "$*" > "$MOCK_DIR/call"
exit "$ATTACH_STATUS"
""")
            (path / "sleep").write_text("""#!/bin/sh
count=$(cat "$MOCK_DIR/count" 2>/dev/null || echo 0)
count=$((count + 1))
echo "$count" > "$MOCK_DIR/count"
if [ "$count" -eq "$BIND_AFTER" ]; then
    mkdir -p "$MOCK_DIR/sdio/mmc2:0001:1/driver"
fi
""")
            for name in ("hciattach", "sleep"):
                (path / name).chmod(0o755)
            env = dict(os.environ, PATH=f"{path}:{os.environ['PATH']}",
                       MOCK_DIR=directory, MICRODUCK_SDIO_SYSFS=str(path / "sdio"),
                       BIND_AFTER=str(bind_after), ATTACH_STATUS=str(attach_status))
            result = subprocess.run(["sh", str(SCRIPT)], env=env, text=True,
                                    capture_output=True, timeout=5)
            call = (path / "call").read_text().strip() if (path / "call").exists() else None
            waits = int((path / "count").read_text()) if (path / "count").exists() else 0
            return result, call, waits

    def test_aic_uses_loaded_firmware_baud_after_binding(self):
        result, call, waits = self.run_init("0xc8a1", bind_after=2)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(call, "-n -s 1500000 /dev/ttyS1 any 1500000 flow")
        self.assertEqual(waits, 2)

    def test_broadcom_initializes_from_boot_baud(self):
        result, call, _ = self.run_init("0x02d0")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(call, "-n -s 115200 /dev/ttyS1 bcm43xx 1500000 flow")

    def test_unknown_radio_never_opens_uart(self):
        result, call, waits = self.run_init("0xffff")
        self.assertNotEqual(result.returncode, 0)
        self.assertIsNone(call)
        self.assertEqual(waits, 15)

    def test_unbound_radio_fails_after_bounded_wait(self):
        result, call, waits = self.run_init("0xc8a1", bind_after=100)
        self.assertNotEqual(result.returncode, 0)
        self.assertIsNone(call)
        self.assertEqual(waits, 15)

    def test_attach_failure_reaches_systemd(self):
        result, _, _ = self.run_init("0xc8a1", attach_status=42)
        self.assertEqual(result.returncode, 42)


if __name__ == "__main__":
    unittest.main()
