# X5 PREEMPT_RT integration validation — 2026-11-13

This record covers the optional X5 integration on top of meta-saha
`3b0de6193f6a7ddbe9d2baa9a8f0a50ef52039f6`, using the pinned Wrynose graph.

## Completed checks

| Check | Result / scope |
| --- | --- |
| Shell syntax | PASS: shared library, build/shell/targets/validate/flash wrappers and shell tests |
| `bash tests/test-build-framework.sh` | PASS in Linux aarch64 with GNU Bash 5.2.37; includes all RT/BPU combinations, explicit build-directory override, all non-X5 targets and invalid RT values rejected before Docker |
| `bash tests/test-flash-rdk-x5.sh` | PASS in the same Linux environment; mocked safety tests only, no physical write |
| `python3 tests/test-rdk-x5-rt-measurement.py` | PASS, four mocked cases: complete receipt, non-RT rejection, initial/final diagnostic failures |
| Docker builder | Project `docker/Dockerfile.yocto-builder` built successfully, Ubuntu 24.04 aarch64, kas 5.5 |
| kas schema/include expansion | PASS for RT/BPU `0/0`, `0/1`, `1/0`, `1/1` using `kas dump` and the same four skip options as `saha-validate`; no repository fetch or BitBake execution |
| Expanded graph contracts | PASS: only RT selects `saha-rt-tests` and the RT variable; only BPU selects the accelerator packagegroup; X5 machine and pinned OE-core revision retained |
| Patch provenance | Public upstream source references retained; cacheinfo recorded hashes/sizes and CoreSight patch hash match |
| Static metadata review | Disabled RT leaves patch selection, config merge/guard and BPU redirection inactive; enabled RT requires the pinned kernel/BPU revisions and expected vendor task layout |
| `git diff --check` | PASS; unified-diff context whitespace is excluded only for kernel patch files |

The shell tests need `rg`, `bzip2`, `partprobe` and `udevadm` in addition to
their usual shell/Python tools. They ran in a disposable Linux container,
without a Docker socket or hardware device mounted. The host's older macOS
Bash 3.2 encounters an existing empty-array/nounset issue in the interactive
`saha-shell` test; the complete Linux suite above passed.

To repeat the focused checks, run from the repository root in Linux:

```bash
bash tests/test-build-framework.sh
bash tests/test-flash-rdk-x5.sh
python3 tests/test-rdk-x5-rt-measurement.py
bash -n scripts/saha-lib scripts/saha-build scripts/saha-shell \
  scripts/saha-targets scripts/saha-validate scripts/saha-flash-rdk-x5
git diff --check
```

## Not completed on the Saha port

The matching external `meta-d-robotics` layer was not available in the
validation environment. Therefore **real BitBake parsing, package compilation
and full image builds remain pending for this Saha integration**. A different
SDK source tree was not substituted for the
pinned BSP. kas expansion validates configuration structure and composition,
not recipe/package availability or successful compilation.

Before deployment, provide the matching BSP and build all four normal/RT and
base/accelerator profiles. Check the final kernel configuration/release,
packaged module ABI, image manifests and installed tools, then qualify the
actual `saha-image-robot` on X5. No board was flashed, rebooted or tested for
this integration. See the [RT guide](../hardware/rdk-x5-preempt-rt.md#validation-and-remaining-qualification)
for the pending hardware qualification scope.
