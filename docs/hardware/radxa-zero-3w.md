# Radxa ZERO 3W

Run `./scripts/saha-build radxa-zero-3w` for the ROS-free Microduck graph.
`SAHA_ROS_DISTRO=none` and `SAHA_HOMEASSISTANT=0` are this target's defaults.
ROS, Home Assistant and RDK accelerator options are rejected before Docker.

The graph pins Wrynose OE-Core/BitBake/meta-openembedded, upstream
`meta-rockchip` at `9d02575bfd9ca5e87c394f593f2bbdbdee914d4e` and `meta-arm`
at `673e8d7c5dcd14de58092eb73e6ecc5eee5c1735`. The machine remains upstream
`radxa-zero-3w`; there is no Rockchip fork. Local hardware changes belong in
`meta-rockchip-saha`, while Microduck application policy is shared.

Output is under `build/radxa-zero-3w/tmp/deploy/images/radxa-zero-3w/`.
The upstream BSP emits a GPT `.wic` and `.wic.bmap` containing its RK3566
DDR/BL31 boot chain, U-Boot and ext4 root filesystem. Building does not write
to an SD card or prove board operation.

Radxa ships AP6256 and AIC8800D80 radio variants. Track their drivers/firmware
separately; do not infer radio support from a successful image build. The
Microduck integration removes the Linux UART2 console/getty and exposes
`ttyS2` as `/dev/serial0`. Earlier boot firmware can still transmit on UART2;
keep actuators quiescent until the board has finished booting.

The Microduck DT enables header I2C3 at 400 kHz (`/dev/i2c-pihat`) and I2S3
with the HAT's AIC3104 codec at address 0x18 and external 12 MHz clock.
`microduck-audio-init` waits for the `aic3104` card, then sets the upstream
speaker mixer levels before robotd starts. Card timeout or mixer failures
are reported by systemd. This assumes the Microduck HAT wiring.

Support is experimental until image, boot, bus, IMU, policy, radio, gamepad
and audio gates in [the Microduck guide](../microduck.md) have evidence.

2026-10-01: `saha-validate` expanded the pinned graph; `saha-shell ... -c
'bitbake -p'` parsed 3,067 recipes with zero errors and selected `linux-yocto`.
The empty thin board layer produced one expected warning before hardware
recipes are added. Framework, flash safety, Bash syntax and whitespace
checks passed. This increment does not yet package the Microduck runtime or
claim a complete image build.

2026-10-02: the HAT DT compiled against checksum-verified upstream Linux
6.18 sources; the resulting 55,521-byte DTB reports sound card `aic3104`.
The pinned board graph parsed 3,177 recipes with zero errors. Audio readiness,
timeout and mixer failure tests, framework/flash regressions and whitespace
checks passed. Actual kernel/image builds and hardware gates remain pending.

Rollback: revert the HAT integration commit. Keep motors disconnected when
using the earlier image with its stock UART2 console.

## Radio variants

The graph includes both SDIO variants. AIC uses Radxa's GPL-2.0 module source
at `d13d07963cd15d731e2895e8288a04cca6152ac9`, applying its pinned Debian
compatibility patches to SDIO only, plus the matching D80 firmware directory.
AP6256 uses mainline `brcmfmac` and the three checksum-pinned AP6256 files from
`radxa/rkwifibt` at `b61a1e8499a4f1956ef417cbcfaa6c2cf805ce08`; the driver maps
its C5 revision to `brcmfmac43456-sdio`. Firmware is conservatively declared
`CLOSED` and the target explicitly accepts `radxa-radio-firmware`.

The DT powers Bluetooth and holds its device wake GPIO high for the userspace
UART transport. The shared helper detects the bound SDIO vendor and initializes
UART1 (`ttyS1`) with AIC H4 or Broadcom HCD. The H4 module loads before BlueZ.
This keeps both board variants in one image without a downstream Rockchip fork.

2026-10-02: pinned graph parse (3,181 recipes, zero errors), actual AIC
fetch/unpack/SDIO patch execution (104 tasks), and actual installation of both
firmware recipes passed. The new DT compiled cleanly with enable/wake GPIOs
17/12 asserted high. Five Bluetooth mock tests and the framework/audio/flash
regressions passed. Actual kernel-module compilation, full package/rootfs QA
and physical radio behavior remain gates for the full image run.

Rollback: revert this radio increment before removing the shared UART helper.

## Pinned boot firmware fetch

The thin layer fetches only the upstream-selected DDR v1.23, shared RK3568
BL31 v1.44 and license from rkbin revision
`f43a462e7a1429a9d407ae52b4745033034a6cf9`. Named SHA256 checks isolate and
validate each cached input; upstream source names, proprietary license checksum
and deploy paths remain intact. The three files total 463,128 bytes and were
checked against the official commit's Git blob IDs. This avoids fetching the
multi-platform binary repository's entire history without a Rockchip fork.

The selected DDR blob is unmodified (`RKBIN_DDR_RECONFIGURE=0`). Requesting
reconfiguration fails explicitly: that path needs the upstream Git history,
parameter file and native tool rather than this selective fetch.

2026-10-02: Docker `saha-shell radxa-zero-3w -c 'bitbake
rockchip-rkbin-ddr rockchip-rkbin-tf-a'` **PASS**, 856 tasks; real checksum
verification, unpack/source staging, license checks, deployment, RPM packaging
and package QA succeeded. Deployed DDR/BL31 hashes match their pinned inputs.
This proves boot-component packaging; the full SD image and board boot have
their own validation gates.

Rollback: revert this fetch correction to restore upstream Git fetching. It
does not change any boot bytes or upstream repository revision.
