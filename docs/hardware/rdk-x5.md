# D-Robotics RDK X5

[Supported hardware](README.md) · [Project README](../../README.md)

Run build and flash-helper commands from the repository root.

## Prerequisites and baseline

RDK X5 uses a separate, pinned Wrynose graph with the
[RDKOS 3.5.0](https://developer.d-robotics.cc/rdk_x_doc/Release_Note/release_note)
/ SDK 1.1.1 release contract and Linux 6.1.83. It does not inherit Tegra layers
or moving branch heads. Provide a local checkout of `meta-d-robotics` through
`SAHA_META_D_ROBOTICS_DIR`; its recipes use fixed official source revisions.

## Build and accelerator variant

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

The target uses `kas/targets/rdk-x5.yml` with pinned ROS 2 Jazzy.
`SAHA_ROS_DISTRO=lyrical` is rejected to prevent an unverified ROS/BSP
combination. Home Assistant is disabled by default; see the shared
[container instructions](../../README.md#home-assistant-container).

For RDK X5, keep the BSP location explicit when overriding paths:

```bash
SAHA_META_D_ROBOTICS_DIR=/path/to/meta-d-robotics \
SAHA_BUILD_DIR=/data/yocto/build-rdk-x5 \
./scripts/saha-build rdk-x5
```

## Output

The RDK X5 image is emitted as a compressed WIC disk image:

```text
build/rdk-x5/tmp/deploy/images/rdk-x5/saha-image-robot-rdk-x5.rootfs-*.wic.bz2
```

With `SAHA_X5_ACCELERATORS=1`, use the equivalent artifact under
`build/rdk-x5-accelerators/tmp/deploy/images/rdk-x5/`.  Keeping that output
separate prevents an accelerator build from overwriting the base-image result.

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

## Network policy

NetworkManager manages WiFi only. Onboard Ethernet, USB host adapters, and
USB gadget interfaces stay on systemd-networkd. See the shared
[WiFi commands](../../README.md#device-networking).

## Image scope

The isolated `meta-rdk-x5-saha` layer supplies `saha-image-robot`. It includes
the RDK X5 kernel/DTBs, RDKOS-compatible `boot.scr`, fixed `CONFIG` partition,
OpenSSH bring-up access, NetworkManager with `nmcli` for WiFi, deterministic
systemd-networkd policies for the non-WiFi interfaces, core robot tools, and
the verified Jazzy ROS 2 runtime. It intentionally does not ship or flash a
replacement bootloader. `SAHA_X5_ACCELERATORS=1` adds only the pinned
accelerator packagegroups through a separate kas include; it is rejected for
Jetson and IQ-9075 targets and does not alter the default RDK X5 image.
