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
stock UART2 console occupies the Microduck motor wires and must be removed
by the board integration increment before connecting motors.

Support is experimental until image, boot, bus, IMU, policy, radio, gamepad
and audio gates in [the Microduck guide](../microduck.md) have evidence.

2026-10-01: `saha-validate` expanded the pinned graph; `saha-shell ... -c
'bitbake -p'` parsed 3,067 recipes with zero errors and selected `linux-yocto`.
The empty thin board layer produced one expected warning before hardware
recipes are added. Framework, flash safety, Bash syntax and whitespace
checks passed. This increment does not yet package the Microduck runtime or
claim a complete image build.
