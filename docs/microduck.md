# Microduck on Saha

The Radxa ZERO 3W and Orange Pi Zero 3W work targets a shared, ROS-free
`saha-image-robot` with the official stable Microduck runtime. BSP layers own
kernel, boot, firmware and device trees; Saha owns runtime dependencies,
services and application configuration. Existing Jetson/RDK/Qualcomm images
keep their ROS selection.

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

The image packages the official stable `daemon-v0.15.0` ARM64 release, source
`a9ec4b2079ef8ee7904014089c885bb07d57d63c`, ONNX Runtime 1.28.0 and policy set
v5. Every archive/model has a SHA256 fetch check. Policies are Apache-2.0 per
the [upstream model card](https://huggingface.co/pollen-robotics/microduck-policies/blob/main/README.md).
Weights and upstream binaries are fetched or reused from a checksum-verified
download cache; they are not copied into this repository. Recipe-specific
`already-stripped` QA exceptions apply to published binaries. Dynamic library
QA remains enabled. The release source/license is fetched alongside its
binaries. This build packages the published runtime; it does not compile Rust
daemon sources.

The enabled units are `robotd`, `configd`, `btd`, `padd`, `mediad` and `updaterd`.
They retain upstream account/sandbox boundaries. `tofd` is installed and may
be enabled when its optional sensor is fitted. BlueZ D-Bus access belongs to
the `btd` account; motor control runs as root. The `robot` group permits IPC
access. `/etc/robot/*.toml` are configuration files preserved by package updates;
no device-specific identity, credentials, private keys or calibration is seeded.

`/opt/robot/daemon/current` selects `releases/0.15.0` and
`/opt/robot/policies/current` selects `releases/seed-v5`. `robotctl` is on PATH.
The runtime loads `/usr/lib/libonnxruntime.so.1` via `ORT_DYLIB_PATH`.
GStreamer uses the MPL-2.0 upstream Microduck v3 WebRTC/RTP plugins and x264
software encoding. A low-rate test source keeps the control channel available
without a qualified camera/NPU/MPP stack. OpenGL and PulseAudio backfill is
explicitly disabled in this headless distro; GST optional GUI plugins are
excluded. The accepted commercial flags are scoped to x264 and its GST plugin.

Generic commissioning starts with `policy.enabled=false`, a 50 Hz loop and
ordinary Sync Read. Fit/commission the bus and IMU, validate HOME and mounting,
then change the policy setting before requesting motion. Board-specific 5 V
HAT builds use `policy.voltage_adapt=false`, `nominal_voltage=5.0` and disable
the upstream 2S-battery empty-pack shutdown. A regulated motor rail is not a
state-of-charge measurement. The upstream fall/thermal/bus guards remain
enabled. Robot geometry/calibration requires separate commissioning. Microduck
0.15.0 does not accept the older `[battery]` or `[body_imu]` parameter tables;
do not transplant them from a different daemon version.

Scheduled upstream OTA is disabled: Debian release hooks install packages with
apt and have not been qualified for Yocto. The updater serves status with a
distinct `saha-daemon-v` feed prefix and no non-root mutation allowlist. Do not
apply the ordinary Debian daemon feed. Qualified Saha package/image updates
must retain board calibration and use the recorded rollback procedure.

The `.tar.zst` rootfs accompanies the board SD `.wic` for inspection/emulation.
A successful build must be followed by rootfs, service, library and model
checks before claiming runtime validation. Physical radio, bus timing and gait
stability still require board evidence.

2026-10-01 runtime metadata milestone: image task dry-run passed 8,066 tasks.
After narrowing headless media/default features, the final graph parsed with
zero errors and resolved 297 recipes, containing no ROS, Docker, Rust compiler,
LLVM or Mesa provider. Framework/flash regressions and TOML/whitespace checks
passed. Full package and image QA remains a subsequent validation step. Model
downloads used locally cached v5 bytes checked against the recipe SHA256s;
direct Hugging Face access from this host timed out.
