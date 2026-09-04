# meta-saha

`meta-saha` is a Yocto Project distro layer and build framework for NVIDIA Jetson, D-Robotics RDK X5, and Qualcomm Dragonwing IQ-9075 systems. The primary workflow builds images with kas inside Docker, so the host only needs Docker and does not need kas, bitbake, vcstool, or Yocto build packages installed.

The Jetson baseline is Yocto Project 6.0 Wrynose and OE4T `meta-tegra` Wrynose, targeting JetPack 7.2 / L4T R39.2.0. RDK X5 uses a separate, pinned Wrynose graph with the [RDKOS 3.5.0](https://developer.d-robotics.cc/rdk_x_doc/Release_Note/release_note) / SDK 1.1.1 release contract and Linux 6.1.83; it does not inherit Tegra layers or moving branch heads.

## Supported targets

| Target alias | OE4T `MACHINE` | Hardware |
| --- | --- | --- |
| `orin-nx-16g-p3768` | `p3768-0000-p3767-0000` | Jetson Orin NX 16GB module in P3768 carrier |
| `agx-thor-devkit` | `jetson-agx-thor-devkit` | Jetson AGX Thor devkit |
| `agx-orin-devkit` | `jetson-agx-orin-devkit` | Jetson AGX Orin devkit |
| `rdk-x5` | `rdk-x5` | D-Robotics RDK X5 development board |
| `iq-9075-evk` | `iq-9075-evk` | Qualcomm Dragonwing IQ-9075 EVK |

List targets with:

```bash
./scripts/saha-targets
```

## Prerequisites

- Docker with permission to run containers as your user.
- Enough disk space for a Yocto build. A first build can consume hundreds of GB across build output, downloads, and sstate cache.
- Network access to fetch Yocto, OpenEmbedded, OE4T, NVIDIA, and D-Robotics sources.
- For `iq-9075-evk`, network access and any credentials required by Qualcomm's
  proprietary firmware recipes. The public machine metadata is pinned, but
  vendor artifact availability is checked during the build.
- For `rdk-x5`, a local checkout of the `meta-d-robotics` BSP layer. Its recipes use fixed official D-Robotics source revisions; pass its location through `SAHA_META_D_ROBOTICS_DIR`.

No host-side Yocto package setup is part of the primary build path.

## Build

From the `meta-saha` repository root:

```bash
./scripts/saha-build orin-nx-16g-p3768
```

Build the other priority targets with:

```bash
./scripts/saha-build agx-thor-devkit
./scripts/saha-build agx-orin-devkit
```

Build the standard Qualcomm IQ-9075 EVK target with the same Docker + kas
workflow:

```bash
./scripts/saha-build iq-9075-evk
```

The IQ-9075 graph is pinned to Qualcomm `meta-qcom` Wrynose and ROS 2 Jazzy.
It intentionally rejects `SAHA_ROS_DISTRO=lyrical` until that combination is
verified. The `iq-9075-evk-open-fw` machine is a separate upstream variant and
is not selected by this target.

The silicon/platform reference is Qualcomm's [IQ-9075 product
page](https://www.qualcomm.com/internet-of-things/products/iq9-series/iq-9075);
the machine and image behavior come from the upstream
[`meta-qcom`](https://github.com/qualcomm-linux/meta-qcom) Wrynose layer.

Build RDK X5 with its BSP layer mounted read-only:

```bash
SAHA_META_D_ROBOTICS_DIR=/path/to/meta-d-robotics \
  ./scripts/saha-build rdk-x5
```

Build the RDK X5 accelerator variant when BPU inference and the selected camera
runtime are required:

```bash
SAHA_META_D_ROBOTICS_DIR=/path/to/meta-d-robotics \
SAHA_X5_ACCELERATORS=1 \
  ./scripts/saha-build rdk-x5
```

This opt-in variant uses the separately mounted `meta-d-robotics` layer and a
separate build directory.  It installs the pinned D-Robotics DNN, multimedia,
BPU hardware-I/O, and camera runtime packagegroups.  It supports the bundled
`imx219`, `imx415`, `sc132gs`, and `sc230ai` sensor plugins; it does not make
other sensor combinations supported.  The BPU module is built against the
pinned RDKOS 3.5.0 Linux 6.1.83 ABI, rather than being copied across kernel
versions.

The accelerator image also includes `saha-rdk-x5-bpu-smoke`, an end-to-end
driver check built around D-Robotics' official RDK X5 HIMLoco policy for a
Unitree Go2. The bundled Bayes-e model and source-indexed observation are
checksum-pinned; D-Robotics validates this model with DNN Runtime 1.24.5 and
HBRT 3.15.55, matching this image's pinned accelerator runtime. On the booted
accelerator image, run:

```bash
saha-rdk-x5-bpu-smoke
```

It validates the policy's `obs_history` float32 `[1,270]` input and
`actions` float32 `[1,12]` output, allocates DNN/BPU memory, submits one
inference, waits for completion, checks that all 12 actions are finite, and
confirms that `bpu_hw_io_x5` is loaded. Success prints `BPU_SMOKE_PASS
algorithm=himloco-go2` with a deterministic output hash. This is offline
algorithm validation only: the command does not access motors or issue robot
control commands. A nonzero exit and `BPU_SMOKE_FAIL stage=...` identify the
failed runtime stage. The base RDK X5 image deliberately does not include this
command, the DNN runtime, or the BPU driver.

The script builds the Docker builder image, mounts persistent cache directories, then runs a target-specific kas graph. Jetson targets use:

```bash
kas build kas/targets/<target>.yml:kas/include/ros-distro-jazzy.yml
```

`rdk-x5` uses `kas/targets/rdk-x5.yml`, which pins the RDK-compatible layers and ROS 2 Jazzy. `jazzy` is also the default ROS 2 distro for Jetson. Build the same Jetson `saha-image-robot` image with ROS 2 Lyrical by setting `SAHA_ROS_DISTRO`:

```bash
SAHA_ROS_DISTRO=lyrical ./scripts/saha-build orin-nx-16g-p3768
```

RDK X5 deliberately rejects `SAHA_ROS_DISTRO=lyrical`; the independent compatibility graph prevents an unverified ROS/BSP combination from entering an otherwise reproducible build.

The IQ-9075 target uses `kas/targets/iq-9075-evk.yml`, which includes the
Qualcomm-specific graph and its pinned ROS 2 Jazzy layer. Home Assistant is
selected by the same `SAHA_HOMEASSISTANT` option as the other targets.

## Output and caches

Default host paths:

| Path | Purpose |
| --- | --- |
| `build/<target>/` | Default target-specific kas/bitbake build directory for `SAHA_ROS_DISTRO=jazzy` |
| `build/<target>-ros-<distro>/` | Target-specific kas/bitbake build directory for non-default ROS distros such as `lyrical` |
| `build/rdk-x5-accelerators/` | Isolated RDK X5 build directory when `SAHA_X5_ACCELERATORS=1` |
| `build/iq-9075-evk/` | IQ-9075 EVK build directory for the pinned Jazzy graph |
| `downloads/` | Shared Yocto download cache |
| `sstate-cache/` | Shared Yocto sstate cache |

Images are emitted under:

```text
build/<target>/tmp/deploy/images/<machine>/
```

RPM packages are emitted under:

```text
build/<target>/tmp/deploy/rpm/
```

Generate RPM feed metadata after a build with:

```bash
./scripts/saha-shell orin-nx-16g-p3768 -c "bitbake package-index"
```

For `orin-nx-16g-p3768`, the current tegraflash archive is emitted at:

```text
build/orin-nx-16g-p3768/tmp/deploy/images/p3768-0000-p3767-0000/saha-image-robot-p3768-0000-p3767-0000.rootfs.tegraflash-tar.zst
```

For non-default ROS distros, use the distro-specific build directory. For example, `SAHA_ROS_DISTRO=lyrical` emits the Orin NX archive under:

```text
build/orin-nx-16g-p3768-ros-lyrical/tmp/deploy/images/p3768-0000-p3767-0000/saha-image-robot-p3768-0000-p3767-0000.rootfs.tegraflash-tar.zst
```

The RDK X5 image is emitted as a compressed WIC disk image:

```text
build/rdk-x5/tmp/deploy/images/rdk-x5/saha-image-robot-rdk-x5.rootfs-*.wic.bz2
```

With `SAHA_X5_ACCELERATORS=1`, use the equivalent artifact under
`build/rdk-x5-accelerators/tmp/deploy/images/rdk-x5/`.  Keeping that output
separate prevents an accelerator build from overwriting the base-image result.

The IQ-9075 image emits Qualcomm's flash package directory and compressed
archive under:

```text
build/iq-9075-evk/tmp/deploy/images/iq-9075-evk/saha-image-robot-iq-9075-evk.rootfs.qcomflash/
build/iq-9075-evk/tmp/deploy/images/iq-9075-evk/saha-image-robot-iq-9075-evk.rootfs.qcomflash.tar.gz
```

The package contains the rootfs, kernel/device-tree and vendor partition or
boot files produced by the upstream `qcomflash` image class. It may require
Qualcomm-provided firmware access during the build. No QDL/EDL command is run
by `meta-saha`; flash instructions will be provided separately after hardware
and the exact EVK revision are available.

All Saha robot images use `sahaWorld` as the default static hostname.

## Hardware handoff

The current work stops at Dockerized kas validation and image packaging; no
IQ-9075 hardware is connected and no device is written. Before a Qualcomm
flash, confirm the physical EVK revision, obtain the vendor flashing tools and
firmware authorization, and ask for the target-specific QDL/EDL procedure.
The generated `.qcomflash` directory and `.tar.gz` archive are the handoff
artifacts for that later step.

## Jetson flash and first boot access

Unpack the `.tegraflash-tar.zst` archive on an x86-64 Linux host, put the Jetson in recovery mode with the USB OTG port connected, then run `initrd-flash`:

```bash
mkdir -p ~/scratch/saha-flash
cd ~/scratch/saha-flash
tar xf /path/to/saha-image-robot-p3768-0000-p3767-0000.rootfs.tegraflash-tar.zst
lsusb -d 0955:
./initrd-flash
```

After first boot, the image includes `l4t-usb-device-mode`, which creates the target-side USB network endpoint at `192.168.55.1` and serves the host side by DHCP. For bring-up, root login is enabled with an empty password:

```bash
ssh root@192.168.55.1
```

If USB networking is not enumerated by the host, use the serial console instead, for example:

```bash
minicom -D /dev/ttyUSB0
```

Change the empty root password before using the image outside bring-up.

### WiFi on the device

Saha images include NetworkManager with `nmcli` for WiFi setup. NetworkManager
manages WiFi only. On Jetson, USB gadget networking (`l4tbr0`,
`192.168.55.1`) stays on systemd-networkd. On RDK X5, onboard Ethernet, USB
host adapters, and USB gadget interfaces also stay on systemd-networkd, so
enabling WiFi does not disturb the existing bring-up paths.

```bash
nmcli dev wifi list
nmcli dev wifi connect "YOUR_SSID" password "YOUR_PASSWORD"
nmcli dev status
ip addr show wlan0
```

If the WiFi interface name is not `wlan0`, use the name shown by `nmcli dev status`.

## RDK X5 TF-card image

Use the guarded flash helper to write a chosen RDK X5 WIC image to a TF card.
First use `lsblk` to identify the whole removable card, unmount its partitions,
then pass both the image and disk explicitly. Do not pass a partition such as
`/dev/sdX1`.

```bash
lsblk -o NAME,SIZE,MODEL,TRAN,RM,MOUNTPOINTS
sudo umount /dev/sdX1 /dev/sdX2

./scripts/saha-flash-rdk-x5 \
  --image build/rdk-x5/tmp/deploy/images/rdk-x5/saha-image-robot-rdk-x5.rootfs-<timestamp>.wic.bz2 \
  --device /dev/sdX
```

The helper validates the bzip2 archive and image size, accepts only an
unmounted removable whole disk, requires the resolved device path to be typed
again on a TTY, writes with `conv=fsync`, and confirms the `CONFIG` and `rootfs`
labels afterwards. If the desktop auto-mounts either newly written partition,
the helper unmounts that target partition and flushes the whole device before
reporting success. Use `--dry-run` to perform the non-writing preflight:

```bash
./scripts/saha-flash-rdk-x5 --dry-run --image <image.wic.bz2> --device /dev/sdX
```

It does not choose an image or device automatically, unmount anything before
the destructive confirmation, write NAND/eMMC firmware, change a bootloader,
or access the serial port.

The resulting card has the RDKOS-compatible MBR layout: a fixed 256 MiB
`CONFIG` FAT volume beginning at 4 MiB, followed by the ext4 robot rootfs.
`CONFIG` is checked by `fsck.vfat` before systemd mounts it, so an interrupted
UMS session or power loss can repair the FAT dirty state before use. Its boot
script loads the kernel and device tree from the card; the build and image
never write the board's persistent boot storage. On first boot, the included
`systemd-networkd` profile requests DHCP on the board's `eth0` interface.

For an accelerator image, select the timestamped `.wic.bz2` file from
`build/rdk-x5-accelerators/tmp/deploy/images/rdk-x5/` instead.  The disk layout
and boot contract are identical to the base RDK X5 image.

RDKOS 3.5.0's vendor 6.1.83 kernel is incompatible with Wrynose's optional
`lttng-modules` ptest dependency. The RDK X5 layer therefore disables only the
`lttng-tools` ptest package; regular LTTng userspace and ROS 2 tracing
dependencies remain available, while kernel LTTng-module tests are excluded.

Override cache/build locations with environment variables:

```bash
SAHA_BUILD_DIR=/data/yocto/build-orin \
SAHA_DOWNLOADS_DIR=/data/yocto/downloads \
SAHA_SSTATE_DIR=/data/yocto/sstate-cache \
./scripts/saha-build orin-nx-16g-p3768
```

For RDK X5, keep the BSP location explicit when overriding paths:

```bash
SAHA_META_D_ROBOTICS_DIR=/path/to/meta-d-robotics \
SAHA_BUILD_DIR=/data/yocto/build-rdk-x5 \
./scripts/saha-build rdk-x5
```

Override the Docker image tag with:

```bash
SAHA_BUILDER_IMAGE=my-saha-builder:wrynose ./scripts/saha-build orin-nx-16g-p3768
```

## Network proxies

`saha-build`, `saha-shell`, and `saha-validate` pass standard proxy variables into both Docker image builds and Docker containers:

```text
HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
http_proxy https_proxy all_proxy no_proxy
```

If none of those variables are present in the current environment, the scripts try to read them from a login interactive `zsh` session. This supports setups where proxy exports live in `~/.zshrc`. Disable this fallback with:

```bash
SAHA_LOAD_ZSHRC_PROXY=0 ./scripts/saha-build orin-nx-16g-p3768
```

If the container can reach upstream sources directly but the host proxy is unstable under Yocto fetch load, force a proxy-free container environment:

```bash
SAHA_NO_PROXY=1 ./scripts/saha-build orin-nx-16g-p3768
```

Dry-run output shows only proxy variable names, not proxy values:

```bash
SAHA_DRY_RUN=1 ./scripts/saha-build orin-nx-16g-p3768
```

## Build tuning

The wrapper defaults to conservative Yocto parallelism to avoid overloading local proxies and developer workstations:

```text
SAHA_BB_NUMBER_THREADS=4
SAHA_BB_NUMBER_PARSE_THREADS=4
SAHA_PARALLEL_MAKE="-j 4"
```

Override these when the network and machine can support more concurrency:

```bash
SAHA_NO_PROXY=1 \
SAHA_BB_NUMBER_THREADS=8 \
SAHA_BB_NUMBER_PARSE_THREADS=8 \
SAHA_PARALLEL_MAKE="-j 8" \
./scripts/saha-build orin-nx-16g-p3768
```

## Interactive shell

Open a Dockerized kas shell for a target:

```bash
./scripts/saha-shell orin-nx-16g-p3768
```

This uses the same mounts and builder image as `saha-build`.

## Validate configuration

Validate a target kas configuration without fetching repositories or starting a build:

```bash
./scripts/saha-validate orin-nx-16g-p3768
```

This is a fast schema/include/config expansion check. A full `saha-build` still depends on network checkout and bitbake.

## Home Assistant container

On Jetson and IQ-9075, `saha-image-robot` includes Docker, the official Home Assistant container launcher, and a preloaded Home Assistant container image by default. Disable that stack at build time with:

```bash
SAHA_HOMEASSISTANT=0 ./scripts/saha-build orin-nx-16g-p3768
```

This omits `docker`, the Home Assistant launcher, the preloaded tarball, and the extra rootfs space reserved for it. ROS 2, USB gadget networking, and WiFi support are unaffected.

The RDK X5 image does not enable this optional packagegroup by default.

During the Yocto build, `saha-homeassistant-container-image` installs the image at `/usr/share/saha/homeassistant/image.tar`. On first boot, `homeassistant-container.service` uses any existing local Docker image first, otherwise runs `docker load` from that tarball, and only pulls remotely when `SAHA_HOMEASSISTANT_PULL=1`.

### Build-time image source priority

While building `saha-homeassistant-container-image`, bitbake uses the first available source:

1. `${DL_DIR}/homeassistant-container.tar` (default host path: `downloads/homeassistant-container.tar`)
2. A local Docker image via the host Docker socket (`SAHA_USE_HOST_DOCKER=1`, default)
3. Remote registry fetch with `skopeo`

Export your local Docker image into the shared download cache:

```bash
docker pull --platform linux/arm64 ghcr.io/home-assistant/home-assistant:stable
docker save ghcr.io/home-assistant/home-assistant:stable -o downloads/homeassistant-container.tar
./scripts/saha-build orin-nx-16g-p3768
```

The Jetson target needs the `linux/arm64` image. An amd64-only local image is skipped automatically.

Disable host Docker reuse during Yocto builds with:

```bash
SAHA_USE_HOST_DOCKER=0 ./scripts/saha-build orin-nx-16g-p3768
```

After flashing, Home Assistant can start offline as long as the preloaded image is present.

Defaults live in `/etc/default/homeassistant-container`:

| Variable | Default |
| --- | --- |
| `SAHA_HOMEASSISTANT_CONFIG_DIR` | `/var/lib/homeassistant` |
| `SAHA_HOMEASSISTANT_IMAGE` | `ghcr.io/home-assistant/home-assistant:stable` |
| `SAHA_HOMEASSISTANT_IMAGE_TAR` | `/usr/share/saha/homeassistant/image.tar` |
| `SAHA_HOMEASSISTANT_CONTAINER_NAME` | `homeassistant` |
| `SAHA_HOMEASSISTANT_TIMEZONE` | `UTC` |
| `SAHA_HOMEASSISTANT_PULL` | `0` |

Set `SAHA_HOMEASSISTANT_PULL=1` to fall back to `docker pull` when the preloaded tarball is missing.

Then open:

```text
http://<device-ip>:8123
```

Check service status on the device:

```bash
systemctl status homeassistant-container docker
journalctl -u homeassistant-container -b --no-pager
ls -lh /usr/share/saha/homeassistant/image.tar
/usr/bin/saha-homeassistant-container start
docker images
docker ps -a
```

If the service failed on first boot, reload the preloaded image manually:

```bash
docker load -i /usr/share/saha/homeassistant/image.tar
systemctl restart homeassistant-container
```

## ROS 2

`saha-image-robot` includes ROS 2 by default through `ros-base` and `ros2cli-common-extensions`. There is no separate ROS image target; build and flash `saha-image-robot` for the robot rootfs.

Supported ROS 2 distros:

| Target family | `SAHA_ROS_DISTRO` | kas include |
| --- | --- | --- |
| Jetson | `jazzy` | `kas/include/ros-distro-jazzy.yml` |
| Jetson | `lyrical` | `kas/include/ros-distro-lyrical.yml` |
| RDK X5 | `jazzy` | selected by `kas/targets/rdk-x5.yml` |
| IQ-9075 EVK | `jazzy` | selected by `kas/targets/iq-9075-evk.yml` |

On Jetson only:

| `SAHA_HOMEASSISTANT` | Effect |
| --- | --- |
| `1` (default) | Include Docker and the preloaded Home Assistant image |
| `0` | Omit Docker, Home Assistant launcher, and preloaded image |

After flashing, initialize the ROS environment with:

```bash
source /opt/ros/<distro>/setup.sh
ros2 --help
```

## Image scope

The supported image target is `saha-image-robot`. On Jetson it is layered on the reusable `saha-image-base` recipe and includes the Jetson BSP base, CUDA runtime libraries, OpenSSH bring-up access, USB device-mode networking support, NetworkManager with `nmcli` for WiFi, the configured ROS 2 runtime and CLI tools, and by default Docker with the official Home Assistant container launcher.

For RDK X5, the same image name is supplied by the isolated `meta-rdk-x5-saha` layer. It includes the RDK X5 kernel/DTBs, RDKOS-compatible `boot.scr`, fixed `CONFIG` partition, OpenSSH bring-up access, NetworkManager with `nmcli` for WiFi, deterministic systemd-networkd policies for the non-WiFi interfaces, core robot tools, and the verified Jazzy ROS 2 runtime. It intentionally does not ship or flash a replacement bootloader.  `SAHA_X5_ACCELERATORS=1` adds only the pinned accelerator packagegroups through a separate kas include; it is rejected for Jetson and IQ-9075 targets and does not alter the default RDK X5 image.

For IQ-9075, the `meta-qcom-saha` layer supplies only the distro/image
composition; Qualcomm's `meta-qcom` layer remains responsible for the kernel,
device trees, firmware, UFS partition layout, U-Boot/UEFI and `qcomflash`
packaging. This keeps the shared Saha application stack independent of the
vendor BSP contract.

The image does not include CUDA samples or Jetson GPU container runtime tooling. Add `nvidia-container-toolkit` later through an optional image or kas include if GPU-backed containers are required; OE4T R39.2 removed the old `nvidia-docker` recipe.

## Add a target

1. Confirm the machine exists in OE4T `meta-tegra` Wrynose.
2. Add an alias to `scripts/saha-lib`.
3. Add `kas/targets/<alias>.yml` with the matching `machine`.
4. Run:

```bash
bash tests/test-build-framework.sh
./scripts/saha-validate <alias>
```

## Removed legacy flow

The old `resources/*.repos`, `scripts/init.sh`, `setup-env`, `scripts-setup/`, local machine templates, and Xavier NX / `rolling-nx` support have been removed. The supported path is Docker plus kas through `scripts/saha-build`.

## License

This project is open sourced under Apache 2.0 License.

The source code originally forked from OE4T `tegra-demo-distro` is under the MIT License; see `docs/licenses/OE4T.license`.
