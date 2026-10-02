# Microduck on Saha

The Radxa ZERO 3W and Orange Pi Zero 3W work targets a shared, ROS-free
`saha-image-robot` with the official stable Microduck runtime. BSP layers own
kernel, boot, firmware and device trees; Saha owns runtime dependencies,
services and application configuration. Existing Jetson/RDK/Qualcomm images
keep their ROS selection.

## Current software baseline: auto-selected daemon 0.15.1

2026-10-02: Saha `3e4752a`/`2cd9d0a` selected the newest stable upstream daemon
release for each board and froze the tag, exact source commit and published
archive SHA256 in per-build locks. The selected release was 0.15.1 for both.
The complete 5,184-task Radxa and 6,446-task Orange Pi image builds passed,
including release/archive validation, package/image QA and SPDX/SBOM. Both new
rootfs archives and SD images passed inspection. Isolated ARM64 execution passed
all eleven binaries, nine systemd units, ten model warmups, updater self-test,
config IPC, media pipelines and 60-second FakeIo walks. Each walk had 60 healthy
samples; Radxa had zero missed ticks and Orange Pi had one under emulation.
Physical boot, peripherals, real-time behavior and gait remain unverified.

| Target | Build tasks | Rootfs packages | SD artifact SHA256 |
| --- | ---: | ---: | --- |
| `radxa-zero-3w` | 5,184 | 1,249 | `.wic` `785721a548a58ddffb78afe1dfbcb0fc845214295b9ee541041944e49234bcae` |
| `orangepi-zero3w` | 6,446 | 677 | `.wic.gz` `60d06f2e60d75550d9bccb9ca9ec62eb64d8d7c97e5a0731feea695d60846650` |

The A733 raw WIC SHA256 is
`24597eca79c1443208abefe7dc16ad194b65ec548473d3037ca6d58755c926a7`.
New reports are `build/validation/<target>/rootfs-auto-release.json`,
`boot-auto-release.json` and `runtime-auto-release/runtime.json`; the matching
JSON lock lives in `build/<target>/release-locks/`.

## Previous pinned 0.15.1 software baseline

2026-10-02: Saha `dc65bf9` pins the [upstream stable 0.15.1 release](https://github.com/pollen-robotics/microduck/releases/tag/daemon-v0.15.1),
source `1fa84386f07884e27866411bc1ba166977bced95` and published ARM64 archive
SHA256 `b1a10b6c2bd99e4de42774818cf94d6d1ca5a9f875e82698d68d8d5ae287eb2c`.
Both complete image builds, package/image QA, SPDX/SBOM, rootfs and SD boot
inspection passed. The isolated ARM64 suites passed all eleven binaries, nine
systemd units, updater self-test, ten ONNX model warmups, config IPC and
error-checked test-source media. Each 60-second FakeIo walk recorded 60 healthy
samples with zero missed ticks. Physical boot, peripherals and gait remain
unverified.
The published 0.15.1 `padd` and `mediad` units no longer pull a deliberately
stopped `robotd` back into service; both images contain the upstream unit bytes.

| Target | Build tasks | Rootfs packages | SD artifact SHA256 |
| --- | ---: | ---: | --- |
| `radxa-zero-3w` | 5,183 | 1,249 | `.wic` `ec110db641e34178e3300019452178b1533bffbd7a7669f66f1f71a15508963a` |
| `orangepi-zero3w` | 6,445 | 677 | `.wic.gz` `060f7b97ac4b3828327ab276e25fc498d8eb6497c354617a1f0ab2c8dd88ad13` |

The A733 raw WIC SHA256 is
`05d8fcea6daba01b9d85b43c3c937bea01481ed5b952b3a9257df8b092c64064`.
Local reports are `build/validation/<target>/rootfs-0151.json`, `boot-0151.json`
and `runtime-0151/runtime.json`. The prior 0.15.0 result remains below as a
separate rollback baseline.

## Following official daemon releases

`scripts/saha-build` now resolves the newest stable upstream `daemon-vX.Y.Z`
release at the start of each Microduck build. It ignores development/prerelease
tags, verifies that the official ARM64 archive has a SHA256 digest, resolves the
tag to an exact Git commit, and writes both BitBake variables and a JSON lock
under `build/<target>/conf/`. A copy of each distinct lock is kept
under `build/<target>/release-locks/`. The current lock is also embedded in the
image as `/usr/share/saha/microduck/runtime-source` (version, revision and
archive SHA256). Ordinary build commands need no version edits:

```sh
scripts/saha-build radxa-zero-3w
scripts/saha-build orangepi-zero3w
cat build/radxa-zero-3w/conf/microduck-release.lock.json
```

For a reproducible rebuild, point either board at a saved JSON lock:

```sh
SAHA_MICRODUCK_RELEASE_LOCK=build/radxa-zero-3w/release-locks/<lock>.json \
    scripts/saha-build orangepi-zero3w
```

This avoids release API/tag lookups; a fully offline build still requires the
sources and archive in BitBake's download cache.
`SAHA_MICRODUCK_RELEASE=0.15.1` instead selects a named stable release through
the API and needs network access. `saha-shell` reuses its build directory's
active lock by default, so inspection does not silently advance a previous
build; set either variable to select a different release. `saha-validate` only
checks kas configuration and does not resolve a release.

Automatic selection does not automatically qualify a new daemon. The recipe
checks archive version, source revision and the eleven expected binaries; the
usual license, fetch checksum, package and image checks still apply. A changed
config schema, service contract, license or binary set requires a reviewed Saha
change and both-board validation. If the latest release or GitHub is unavailable,
the build fails instead of silently falling back to an older release. The
qualified daemon release is 0.15.1 at the time of this record; a future release
needs the same checks before it can be called qualified.

## Previous 0.15.0 software baseline

2026-10-02: clean Saha metadata `b03ae0f` completed both full image builds,
using upstream meta-rockchip `9d02575` for Radxa and independent BSP `b3bfd8b`
for A733. Verified sstate was reused in the final builds. Package/rootfs QA,
SD/tar artifacts and SPDX/SBOM passed; actual rootfs and boot inspections and
the isolated ARM64 software suite passed for both platforms.

| Target | Build tasks | Rootfs packages | SD output | Physical qualification |
| --- | ---: | ---: | --- | --- |
| `radxa-zero-3w` | 5,183 | 1,249 | GPT `.wic` + bmap | Pending |
| `orangepi-zero3w` | 6,445 | 677 | MBR `.wic.gz` + bmap | Pending |

Both images include daemon 0.15.0, ONNX Runtime 1.28.0, ten pinned v5 models,
eight enabled runtime/readiness units and no ROS/container stack. Both suites
passed all model inference warmups, config IPC, finite H.264/Opus-RTP pipelines,
target systemd verification and error-checked media startup. Each 60-second
fake walk run yielded 60 healthy samples with no missed ticks. This qualifies
software under emulation; real board timing, peripherals and gait need the
commissioning evidence below. Generic images keep gait disabled until fitted
and commissioned.

Outputs are in `build/<target>/tmp/deploy/images/<target>/`. Local handoff
records are `build/validation/<target>/qualification.json`, `SHA256SUMS`,
`rootfs.json` and `boot.json`. Runtime logs/reports are in Radxa's
`runtime-gst-discovery/` and A733's `runtime/` beneath those directories.
The initial Radxa `runtime/` result was invalidated by media errors and is
marked accordingly; use the corrected report. Frozen build revisions above
precede documentation-only completion updates.

Qualified SD artifact SHA256s:

```text
radxa-zero-3w .wic:    159d697d010667fdc7e7453c77affcc9318a42372f347587806a2a44a339f0af
orangepi-zero3w .wic.gz: 1298f773e459da13cc3689dacb7c9a03ffd4809e2c4295424aa945a17b6d5d4a
orangepi-zero3w raw WIC: 5e6940c19d90b1908cdc5bcebdea78db9008c1b14376a90c63e51963f305a57e
```

The dated increment notes below preserve earlier intermediate/failure levels;
their pending image checks are superseded by this completed software baseline.

## Incremental validation

The common layer loads its ROS packagegroup through `BBFILES_DYNAMIC` only
when `ros2-layer` is present. `kas/check/common-without-ros.yml` checks the
common layer against pinned Wrynose and meta-openembedded, without fetching
meta-ROS or a vendor layer. It selects `core-image-minimal` for a metadata
check and is not a Microduck image build.

2026-10-01: Docker kas 5.5 / BitBake parsed all 2,981 recipes with zero
errors in this graph. The existing build-framework and RDK flash safety
regressions, Bash syntax and whitespace checks passed. The graph contains
no meta-ROS checkout; `packagegroup-saha-ros2` remains available to graphs
that register `ros2-layer`.

The Microduck kas base declares the custom build-tuning environment keys so
kas passes them through to BitBake. Example: `SAHA_BB_NUMBER_THREADS=7`,
`SAHA_BB_NUMBER_PARSE_THREADS=3` and `SAHA_PARALLEL_MAKE='-j 6'` resolve to
`7`, `3` and `-j 6` via `bitbake-getvar --value` inside `saha-shell`.
2026-10-02: this resolver check passed in the pinned Radxa graph. Docker
environment forwarding alone does not prove kas/BitBake received these keys.

Every build claim records the command, source revisions and its actual level:
parse, package, image or hardware. Small Conventional Commits provide rollback
points. Revert consuming commits before changes to their dependencies.

## Runtime contract

The build selects the official stable `daemon-vX.Y.Z` ARM64 release and locks its
source commit and archive SHA256; ONNX Runtime 1.28.0 and policy set v5 remain
pinned. Every archive/model has a SHA256 fetch check. Policies are Apache-2.0 per
the [upstream model card](https://huggingface.co/pollen-robotics/microduck-policies/blob/main/README.md).
Weights and upstream binaries are fetched or reused from a checksum-verified
download cache; they are not copied into this repository. Recipe-specific
`already-stripped` QA exceptions apply to published binaries. Dynamic library
QA remains enabled. The release source/license is fetched alongside its
binaries. This build packages the published runtime; it does not compile Rust
daemon sources.

Source/license inputs use Git revisions, not GitHub-generated source archives:
the locked daemon revision and GST v3 source
`a9a839f274fb20698d3abc2639a28d75421c5471`. Wrynose's `src-uri-bad` check stays
enabled. Published binary archives retain their original SHA256 checks. The
plugin source's Apache license has a leading newline; its exact Git bytes are
audited independently of the daemon's license, without changing license terms.

2026-10-02: Docker checks in the Orange Pi graph passed recipe QA (two tasks),
actual fetch/unpack (26 tasks) and license QA (120 tasks) for both packages.
The initial full Radxa run exposed the source-archive check; the first Git
rerun caught the distinct plugin license bytes. Both failures and the final
passing rerun are retained in the task logs. Full install/package/image QA
remains part of the image build. Revert the source-fetch correction to inspect
the previous archive metadata; that restores the recorded Wrynose rejection.

The enabled units are `robotd`, `configd`, `btd`, `padd`, `mediad` and `updaterd`.
They retain upstream account/sandbox boundaries. `tofd` is installed and may
be enabled when its optional sensor is fitted. BlueZ D-Bus access belongs to
the `btd` account; motor control runs as root. The `robot` group permits IPC
access. `/etc/robot/*.toml` are configuration files preserved by package updates;
no device-specific identity, credentials, private keys or calibration is seeded.

Saha clears the upstream `updaterd` network-online ordering in a unit drop-in.
The original unit remains intact, while local updater status and the dependent
`mediad` startup no longer wait for NetworkManager's 60-second online timeout
on an unprovisioned or offline board.

`/opt/robot/daemon/current` selects the locked `releases/<version>` and
`/opt/robot/policies/current` selects `releases/seed-v5`. `robotctl` is on PATH.
The runtime loads `/usr/lib/libonnxruntime.so.1` via `ORT_DYLIB_PATH`.
GStreamer uses the MPL-2.0 upstream Microduck v3 WebRTC/RTP plugins and x264
software encoding. A low-rate test source keeps the control channel available
without a qualified camera/NPU/MPP stack. OpenGL and PulseAudio backfill is
explicitly disabled in this headless distro; GST optional GUI plugins are
excluded. The accepted commercial flags are scoped to x264 and its GST plugin.

WebRTC also requires the
[debugutilsbad `errorignore` element](https://gstreamer.freedesktop.org/documentation/debugutilsbad/errorignore.html)
to discover encoder caps. The plugin recipe declares this runtime dependency
explicitly. Without it, `mediad` can keep serving HTTP while its WebRTC pipeline
reports that no codec can handle the stream. A live process/HTTP response alone
is insufficient validation.

2026-10-02: the initial ARM64 run exposed this missing element in the actual
media log. A negative probe against that rootfs returned `No such element or
plugin 'errorignore'`. The corrected frozen graph completed all 5,183 build
tasks and rootfs inspection passed with 1,249 packages. Actual plugin probing,
finite video/audio pipelines, all ten ONNX model warmups and `mediad` startup
then passed in isolated ARM64 execution, with no codec-discovery/pipeline
errors. Revert this dependency correction to restore the recorded media failure.

Generic commissioning starts with `policy.enabled=false`, a 50 Hz loop and
ordinary Sync Read. Fit/commission the bus and IMU, validate HOME and mounting,
then change the policy setting before requesting motion. Board-specific 5 V
HAT builds use `policy.voltage_adapt=false`, `nominal_voltage=5.0` and disable
the upstream 2S-battery empty-pack shutdown. A regulated motor rail is not a
state-of-charge measurement. The upstream fall/thermal/bus guards remain
enabled. Robot geometry/calibration requires separate commissioning. Microduck
0.15.1 does not accept the older `[battery]` or `[body_imu]` parameter tables;
do not transplant them from a different daemon version.

Scheduled upstream OTA is disabled: Debian release hooks install packages with
apt and have not been qualified for Yocto. The updater serves status with a
distinct `saha-daemon-v` feed prefix and no non-root mutation allowlist. Do not
apply the ordinary Debian daemon feed. Qualified Saha package/image updates
must retain board calibration and use the recorded rollback procedure. The
0.15.1 updater configuration requires all eleven release binaries before any
future Saha-qualified daemon update can become live.
The upstream `robot-boot-check` service/timer for automatic failed-update boot
recovery is not installed; that recovery path needs a qualified Yocto updater
before it can be enabled. Until then, restore a previous qualified image after
an update failure.

The `.tar.zst` rootfs accompanies the board SD `.wic` for inspection/emulation.
A successful build must be followed by rootfs, service, library and model
checks before claiming runtime validation. Physical radio, bus timing and gait
stability still require board evidence.

## Inspect a built image

Extract the generated rootfs into a new inspection directory, preserving image
permissions. The checker resolves absolute image symlinks inside that directory,
including the usrmerge and `/opt/robot` links; host paths are never substituted.
It requires host Python 3.11+ and `readelf` and does not execute target binaries.

```sh
deploy=build/radxa-zero-3w/tmp/deploy/images/radxa-zero-3w
mkdir -p build/validation/radxa-zero-3w/rootfs
tar --zstd -xf "$deploy/saha-image-robot-radxa-zero-3w.rootfs.tar.zst" \
    -C build/validation/radxa-zero-3w/rootfs --no-same-owner
python3 tests/check-microduck-rootfs.py \
    --rootfs build/validation/radxa-zero-3w/rootfs \
    --manifest "$deploy/saha-image-robot-radxa-zero-3w.rootfs.manifest" \
    --machine radxa-zero-3w \
    --release-lock build/radxa-zero-3w/release-locks/<lock>.json
python3 tests/test-microduck-rootfs.py
```

Substitute `orangepi-zero3w` for the other target. Inspect against the same
release lock and metadata revision used to build the image (`--metadata` accepts
a frozen clone). If `--release-lock` is omitted, the checker uses the active
`build/<machine>/conf/microduck-release.lock.json`.
The checker fails on missing runtime/board/radio packages, ROS/container files,
incorrect release identity, missing direct ELF dependencies, model checksum
changes, unqualified power/OTA defaults, disabled required services or missing
accounts/UART/module metadata. Its JSON report records precisely what passed.

2026-10-02: the frozen `5402a42` Radxa graph completed all 5,183 build tasks,
including AIC SDIO compilation against Linux 6.18.39, package/rootfs/image QA,
WIC, tar rootfs and SPDX. Inspection of that actual rootfs passed: 1,248
packages, all eleven daemon binaries, ONNX/GST dependencies, ten policy models
and eight enabled units. Four symlink regression tests passed. Target execution
and physical board validation are separate gates. Revert the checker increment
to remove this inspection interface; image package behavior is unchanged.

## Inspect SD boot artifacts

Run the boot checker against the matching WIC and extracted archive. It needs
host `sfdisk`, `fdtget`, `debugfs` and `e2fsck`, plus Python 3.11+. It reads the
image as a regular file and checks a temporary copy of the ext4 partition;
no loop device, physical media or mounted filesystem is used.

```sh
deploy=build/radxa-zero-3w/tmp/deploy/images/radxa-zero-3w
python3 tests/check-microduck-boot.py \
    --wic "$deploy/saha-image-robot-radxa-zero-3w.rootfs.wic" \
    --deploy "$deploy" \
    --rootfs build/validation/radxa-zero-3w/rootfs \
    --machine radxa-zero-3w
python3 tests/test-microduck-boot.py
```

For Orange Pi, decompress its `.wic.gz` into a new inspection file and use the
corresponding archive and deploy directory:

```sh
deploy=build/orangepi-zero3w/tmp/deploy/images/orangepi-zero3w
gzip -dc "$deploy/saha-image-robot-orangepi-zero3w.rootfs.wic.gz" \
    > build/validation/orangepi-zero3w/image.wic
python3 tests/check-microduck-boot.py \
    --wic build/validation/orangepi-zero3w/image.wic \
    --deploy "$deploy" \
    --rootfs build/validation/orangepi-zero3w/rootfs \
    --machine orangepi-zero3w
```

The checker validates partition offsets/bounds, GPT CRCs where applicable,
byte-identical boot inputs, ext4 consistency and representative archive/WIC
files. It checks the selected HAT DT, motor UART console removal and codec/I2C
configuration. Radxa uses the FIT's default HAT configuration; A733 requires
both legacy header CRCs, an ARM header with the specified addresses and the
exact AArch64 Image payload. Six regression cases reject corrupt or
incompatible uImages. The JSON report includes the WIC and boot-input hashes.
A passing inspection proves artifact consistency; actual boot is a board gate.

2026-10-02: both actual completed WIC images passed this inspection. Radxa
uses GPT with root at 16 MiB; A733 uses MBR with root at 32 MiB and byte-identical
boot0/TOC1 inputs at the vendor offsets. Both ext4 consistency checks and all
representative archive/WIC comparisons passed. Their selected HAT DTs and
FIT/uImage checks passed. The A733 rootfs checker also passed all contracts
against its 677-package manifest. Six corrupt/incompatible-header tests and
the four image-symlink tests passed. Revert this checker increment to remove
the artifact inspection interface; image contents are unchanged.

## Execute the image software without a board

The runtime checker requires a working ARM64 QEMU `binfmt_misc` registration
inside Docker, with the fix-binary flag, and the documented Wrynose builder
image. It does not install/change the host's emulator registration. Extract
the actual built archive inside a disposable container; keep image/source
mounts read-only and disconnect the container from external networks.

```sh
deploy="$PWD/build/radxa-zero-3w/tmp/deploy/images/radxa-zero-3w"
reports="$PWD/build/validation/radxa-zero-3w/runtime"
mkdir -p "$reports"
docker run --rm --user 0:0 --network none \
    -e SAHA_MICRODUCK_EMULATION=1 \
    -v "$deploy:/image:ro" \
    -v "$PWD/tests/check-microduck-runtime.py:/check.py:ro" \
    -v "$reports:/reports" \
    meta-saha-yocto-builder:wrynose bash -ec '
        mkdir /tmp/target
        tar --zstd -xpf /image/saha-image-robot-radxa-zero-3w.rootfs.tar.zst -C /tmp/target
        python3 /check.py --rootfs /tmp/target --output /reports --seconds 60
    '
```

Substitute `orangepi-zero3w` for the other image. Root is used only inside this
container for chroot and isolated standard character devices. No host D-Bus,
network, robot UART, audio device or physical media is mounted. Every robot
invocation contains `--fake`. Temporary benchmark TOML enables policies and
disables physical audio in the disposable copy; production defaults are retained
in the archive. Fake initialization exercises IPC without commanding a board.

The check executes all eleven ARM64 binaries, probes six required GStreamer
elements, runs finite H.264 and Opus/RTP pipelines, validates nine systemd units
with the image's own `systemd-analyze`, and runs updater's read-only self-test.
Commissioning, v5 walk, alpha walk/stand and roller profiles cover all ten
networks' real load/inference warmups. It samples control-loop progress during
the 60-second walk profile, checks policy errors and fake initialization, then
tests configd IPC with fake Wi-Fi/gamepads and mediad's test-source/HTTP startup.
Media pipeline/discovery errors fail the check even if HTTP remains reachable.
Detailed logs and health samples accompany `runtime.json`.

2026-10-02: the Radxa image with the codec-discovery correction passed this
complete suite. All 60 walk-profile health samples were healthy, with no missed
ticks; all ten model warmups passed. Media discovery and the test-source pipeline
passed after the required dependency was added. This is software execution under
emulation, not measured board timing, radio/audio operation or a gait endurance
test. Revert the runtime-check increment to remove this verification interface.

## Board commissioning and stability record

Promote each exact image only after recording its SHA256, Saha/BSP commits,
board revision, radio variant and HAT wiring. The artifact/emulation reports
qualify software inputs; boot, electrical interfaces and gait need board
measurements. Keep the previous qualified SD image and a separate backup of
`/etc/robot`, identity and calibration for rollback. Upstream Debian OTA stays
disabled; replacing an image requires restoring the appropriate board data.

First boot with actuators disconnected or held quiescent. Earlier boot stages
can transmit on the motor UART despite Linux console removal. Confirm the
kernel/DT and aliases, inspect service failures and audio/radio enumeration,
then commission the Dynamixel bus, body IMU (bus ID 200), HOME and mounting.
An unconnected bus reporting degraded health is expected at this stage.
`policy.enabled=false` disables gait; explicit initialization can still apply
torque. Motion commissioning is a separate operator action.

Read-only evidence commands on the board include:

```sh
uname -a
readlink -f /dev/serial0 /dev/i2c-pihat
systemctl --failed --no-pager
systemctl status robotd configd btd padd mediad updaterd \
    microduck-audio-init microduck-bluetooth-uart --no-pager
journalctl -b -u robotd -u mediad -u microduck-audio-init \
    -u microduck-bluetooth-uart --no-pager
robotctl version --json
robotctl health --json
robotctl net status --json
bluetoothctl list
aplay -l
```

After commissioning, collect control-loop ticks, achieved rate, missed ticks,
bus errors, consecutive stale IMU reads, CPU/temperature and service restart
counts during a sustained run with media, radio and gamepad traffic. Require
no loop stalls, recurring degraded health, model fallback, codec errors or
crash/restart loop; investigate missed-tick/error rates rather than using a
single healthy sample. Test both Radxa radio variants separately. Verify sound
and approved motion on each HAT, including recovery after network loss and a
reboot. Record the chosen test duration/load and observed limits; the present
60-second emulation suite establishes no physical endurance claim.

If a new revision fails, restore the previous qualified image and its matching
configuration/calibration, then repeat the same checks. Reverting one source
commit is a code rollback point; it does not automatically restore mutable
robot state or qualify a newly built image.

## Radio UART transport

`microduck-bluetooth-uart` supplies the shared foreground systemd service for
boards that reserve `/dev/ttyS1` for Bluetooth. It waits up to 15 seconds for
a supported SDIO driver to bind. AIC8800D80 uses H4 at its firmware's 1.5 Mbaud;
AP6256 uses BlueZ's `bcm43xx` HCD initialization from 115200 baud, then switches
to 1.5 Mbaud. Unknown/unbound devices fail without opening any UART. An attach
failure reaches systemd's restart policy. Board packages select this helper;
the motor UART remains independently mapped to `/dev/serial0`.

2026-10-02: five mocked transport tests passed (AIC delayed binding, Broadcom,
unknown device, bounded readiness and attach failure). The pinned Radxa graph
including the package parsed 3,181 recipes with zero errors; framework/audio/
flash regressions and the shell syntax check passed. Real controller behavior
remains a hardware gate.

2026-10-01 runtime metadata milestone: image task dry-run passed 8,066 tasks.
After narrowing headless media/default features, the final graph parsed with
zero errors and resolved 297 recipes, containing no ROS, Docker, Rust compiler,
LLVM or Mesa provider. Framework/flash regressions and TOML/whitespace checks
passed. Full package and image QA remains a subsequent validation step. Model
downloads used locally cached v5 bytes checked against the recipe SHA256s;
direct Hugging Face access from this host timed out.
