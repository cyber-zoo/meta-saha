# Orange Pi Zero 3W (Allwinner A733)

Run `./scripts/saha-build orangepi-zero3w` for the shared ROS-free Microduck
image. This is the A733 board, distinct from Orange Pi Zero 3 / H618.
ROS, Home Assistant and RDK accelerator options are rejected before Docker.

## BSP boundary and build

The standalone `meta-allwinner` repository owns kernel, ARM32 U-Boot, closed
boot assets and the SD layout. The default location is `../meta-allwinner`;
set `SAHA_META_ALLWINNER_DIR=/path/to/meta-allwinner` to override it. Saha
checks the layer identity and mounts it read-only at `/work/meta-allwinner`.
Keep the external BSP's commit in your build records. The initial SD contract
is `950275c` (and its preceding kernel/U-Boot increments).

`kas/targets/orangepi-zero3w.yml` selects pinned Wrynose OE-Core, BitBake and
meta-openembedded plus this external layer, `meta-saha-common`,
`meta-saha-microduck` and `meta-allwinner-saha`. No other vendor/ROS graph is
loaded. The thin Saha layer selects HAT hardware and app defaults; it does not
duplicate the BSP kernel or proprietary packing tools.

```sh
./scripts/saha-validate orangepi-zero3w
./scripts/saha-build orangepi-zero3w
```

The graph explicitly accepts the scoped closed boot firmware/tool flags.
Keep their upstream licensing/provenance separate from the layer's MIT license.
Build inputs stay fixed for the entire run; use a clean fixed checkout/snapshot
when iterating on metadata while another build is active.

## Boot and hardware contract

Output is under `build/orangepi-zero3w/tmp/deploy/images/orangepi-zero3w/`:
`saha-image-robot-*.wic.gz`, `.wic.bmap`, `.tar.zst`, kernel/DT and boot assets.
The MBR image reserves the first 32 MiB, stores boot0 at 8 KiB and the boot
package at 16,400 KiB, and uses ext4 partition 1 as root. An ARM-header uImage
wraps the AArch64 kernel at load/entry 0x41000000. A private ARM32 multiconfig
builds U-Boot without changing the Linux/userspace tune.

The Microduck DT enables UART0 on PB9/PB10 with a 48 MHz clock and RX DMA.
`ttyS0` becomes `/dev/serial0`; Linux serial printk/getty are disabled and the
boot script uses `console=tty1`. Earlier boot stages may still transmit on the
motor UART: keep actuators quiescent through boot. TWI0 at 400 kHz becomes
`/dev/i2c-pihat`. The HAT's AIC3104 codec at 0x18 uses the vendor I2S0 audio
binding; shared mixer initialization waits for sound card `aic3104`.

The vendor kernel already contains the AIC SDIO driver. Do not install Radxa's
out-of-tree module on this machine. GPU/NPU/camera performance and radio/gamepad
operation remain hardware gates. Media starts on the test source until a camera
path is qualified. Policy-driven gait is disabled pending commissioning;
the upstream startup-pose behavior can still apply motor torque.

## Radio firmware and UART

Use `meta-allwinner` revision `e93131a` or later for the eight pinned AIC8800D80
firmware files. Saha accepts the BSP's `allwinner-radio-firmware` flag and
recommends its machine firmware; these files use the in-tree driver's
`/usr/lib/firmware/aic8800d80` path. The board package requires the shared
`microduck-bluetooth-uart` service, and the kernel fragment/modules list enable
the H4 UART transport on `ttyS1`. No Radxa module is used on A733.

2026-10-02: the Saha plus private U-Boot graph parsed 6,198 recipes with zero
errors; actual board-package installation passed all 685 tasks. BitBake
introspection confirmed the UART-helper runtime dependency and accepted radio
flag. Five Bluetooth helper tests and framework/flash regressions passed.
The BSP's firmware package already passed actual build/package QA. Full Saha
rootfs installation, HCI operation and physical radio behavior remain separate
checks.

Rollback: revert this Saha radio consumer before removing the BSP firmware or
shared UART service. Kernel/boot source revisions do not change.

## Evidence and rollback

2026-10-02: wrapper tests covered default sibling lookup, explicit paths with
spaces, read-only mounting, invalid layer paths and incompatible options.
Framework/flash/syntax/whitespace regressions passed. The HAT DT compiled from
the pinned vendor 6.6.98 source to 171,837 bytes; existing vendor-tree DT warnings
remain. The Saha + ARM32 multiconfig graph parsed 6,194 recipes with zero errors
and resolved 6,406 image tasks in a dry-run. Real variable checks selected the
ARM uImage header, Microduck DT and display-only console.

This is metadata/DT validation. Full image/package builds, boot, bus timing,
ONNX inference, audio and radio tests are subsequent gates. See the
[Microduck runtime contract](../microduck.md). Building performs no physical
media write or robot movement.

Rollback: revert the Saha target/overlay commit before reverting the BSP's SD
packaging/U-Boot commits. The common runtime remains usable by the Radxa graph.
