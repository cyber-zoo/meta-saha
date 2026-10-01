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
