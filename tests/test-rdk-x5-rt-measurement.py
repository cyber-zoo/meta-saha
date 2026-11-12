#!/usr/bin/env python3
"""Exercise measurement receipts and diagnostic failures without RT or devices."""
import contextlib
import importlib.machinery
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock

SCRIPT = Path(__file__).resolve().parents[1] / "saha-layers/meta-rdk-x5-saha/recipes-saha/rt-tests/files/saha-rt-tests"
loader = importlib.machinery.SourceFileLoader("saha_rt_tests", str(SCRIPT))
helper = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
with mock.patch.object(sys, "dont_write_bytecode", True):
    loader.exec_module(helper)


class MeasurementTest(unittest.TestCase):
    def setUp(self):
        directory = self.enterContext(tempfile.TemporaryDirectory())
        self.output = Path(directory) / "measurement"
        self.config = "CONFIG_PREEMPT_RT=y\n"
        self.dmesg_status = [0, 0]
        self.cyclic = {"return_code": 0, "num_threads": 1, "thread": {"0": {"cycles": 1000, "max": 23}}}
        self.error = self.stderr = None
        self.enterContext(mock.patch.object(helper, "Path", self.virtual_path))
        self.enterContext(mock.patch.object(helper.gzip, "open", side_effect=lambda *a, **k: io.StringIO(self.config)))
        self.enterContext(mock.patch.object(helper.os, "geteuid", return_value=0))
        self.enterContext(mock.patch.object(helper.os, "uname", return_value=SimpleNamespace(release="6.1.83-rt28")))
        self.run = self.enterContext(mock.patch.object(helper.subprocess, "run", side_effect=self.command))
        self.enterContext(mock.patch.object(helper.subprocess, "Popen", side_effect=AssertionError("unexpected real load")))

    def virtual_path(self, value):
        path = str(value)
        values = {"/sys/kernel/realtime": "1\n", "/proc/sys/kernel/random/boot_id": "test-boot\n",
                  "/proc/cmdline": "root=/dev/mmcblk1p2\n", "/proc/interrupts": "IRQ witness\n",
                  "/sys/devices/system/cpu/online": "0\n"}
        if path == "/sys/devices/system/cpu/cpufreq":
            return SimpleNamespace(glob=lambda pattern: [])
        if path.startswith(("/proc/", "/sys/")):
            return SimpleNamespace(read_text=lambda: values[path])
        return Path(value)

    def command(self, argv, **kwargs):
        if argv == ["dmesg"]:
            status = self.dmesg_status.pop(0)
            return subprocess.CompletedProcess(argv, status, "kernel witness\n", "denied\n" if status else "")
        if argv[0] == "cyclictest":
            output = next(arg.split("=", 1)[1] for arg in argv if arg.startswith("--json="))
            Path(output).write_text(json.dumps(self.cyclic))
            kwargs["stdout"].write("cyclictest witness\n")
            return subprocess.CompletedProcess(argv, 0)
        self.fail("unexpected subprocess: " + repr(argv))

    def invoke(self):
        # Match CLI exit conventions while preventing any actual process/device use.
        with mock.patch.object(sys, "argv", [str(SCRIPT), "--duration", "1", "--output", str(self.output)]), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()) as stderr:
            try:
                helper.main()
            except SystemExit as error:
                self.stderr = stderr.getvalue()
                return error.code
            except RuntimeError as error:
                self.error = error
                return 1
        return 0

    def test_complete_measurement_preserves_logs_and_removes_scratch(self):
        self.assertEqual(self.invoke(), 0)
        result = json.loads((self.output / "result.json").read_text())
        self.assertTrue(result["measurement_complete"])
        self.assertTrue(result["scratch_removed"])
        self.assertEqual(result["cyclictest"], self.cyclic)
        self.assertEqual((self.output / "cyclictest.log").read_text(), "cyclictest witness\n")
        for name in ("kernel.config", "dmesg-before.log", "dmesg-after.log", "interrupts-before.txt", "interrupts-after.txt", "stress.log"):
            self.assertTrue((self.output / name).is_file(), name)
        self.assertEqual(list(self.output.glob("scratch.*")), [])

    def test_non_rt_kernel_is_rejected_before_measurement(self):
        self.config = "# CONFIG_PREEMPT_RT is not set\n"
        self.assertEqual(self.invoke(), 2)
        self.assertIn("running kernel is not PREEMPT_RT", self.stderr)
        self.assertFalse(self.output.exists())
        self.run.assert_not_called()

    def test_initial_dmesg_failure_refuses_cyclictest(self):
        self.dmesg_status = [1]
        self.assertNotEqual(self.invoke(), 0)
        self.assertIn("initial kernel diagnostics", str(self.error))
        self.assertEqual([call.args[0] for call in self.run.call_args_list], [["dmesg"]])
        self.assertIn("denied", (self.output / "dmesg-before.log").read_text())
        self.assertFalse((self.output / "cyclictest.json").exists())

    def test_final_dmesg_failure_invalidates_completed_measurement(self):
        self.dmesg_status = [0, 1]
        self.assertNotEqual(self.invoke(), 0)
        self.assertIn("final kernel diagnostics", str(self.error))
        result = json.loads((self.output / "result.json").read_text())
        self.assertFalse(result["measurement_complete"])
        self.assertEqual(result["cyclictest_exit"], 0)
        self.assertEqual(result["dmesg_after_exit"], 1)
        self.assertIn("denied", (self.output / "dmesg-after.log").read_text())


if __name__ == "__main__":
    unittest.main()
