#!/usr/bin/env python3
"""Exercise card readiness and mixer failures without audio hardware."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "saha-layers/meta-saha-microduck/recipes-robot/audio/files/microduck-audio-init"


class AudioInitTest(unittest.TestCase):
    def run_init(self, ready_after=0, fail_mixer=False):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            (path / "amixer").write_text("""#!/bin/sh
set -eu
echo "$*" >> "$MOCK_DIR/calls"
if [ "$3" = info ]; then
    count=$(cat "$MOCK_DIR/count" 2>/dev/null || echo 0)
    count=$((count + 1))
    echo "$count" > "$MOCK_DIR/count"
    [ "$count" -gt "$READY_AFTER" ]
else
    [ "$FAIL_MIXER" = 0 ]
fi
""")
            (path / "sleep").write_text("#!/bin/sh\nexit 0\n")
            for name in ("amixer", "sleep"):
                (path / name).chmod(0o755)
            env = dict(os.environ, PATH=f"{path}:{os.environ['PATH']}",
                       MOCK_DIR=directory, READY_AFTER=str(ready_after),
                       FAIL_MIXER=str(int(fail_mixer)))
            result = subprocess.run(["sh", str(SCRIPT)], env=env, text=True,
                                    capture_output=True, timeout=5)
            return result, (path / "calls").read_text().splitlines()

    def test_card_can_appear_after_startup(self):
        result, calls = self.run_init(ready_after=2)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(sum(call.endswith(" info") for call in calls), 3)
        self.assertEqual(sum(" cset " in call for call in calls), 4)

    def test_missing_card_fails_after_bounded_wait(self):
        result, calls = self.run_init(ready_after=100)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("card did not appear", result.stderr)
        self.assertEqual(len(calls), 15)
        self.assertFalse(any(" cset " in call for call in calls))

    def test_mixer_error_is_not_reported_as_success(self):
        result, calls = self.run_init(fail_mixer=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(sum(" cset " in call for call in calls), 1)


if __name__ == "__main__":
    unittest.main()
