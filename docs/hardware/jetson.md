# NVIDIA Jetson

[Supported hardware](README.md) · [Project README](../../README.md)

Run build commands from the repository root. The baseline and supported
boards are listed in the root [Supported targets table](../../README.md#supported-targets).

## Build and software variants

```bash
./scripts/saha-build orin-nx-16g-p3768
./scripts/saha-build agx-thor-devkit
./scripts/saha-build agx-orin-devkit
```

The target graph composes `kas/targets/<target>.yml` with
`kas/include/ros-distro-jazzy.yml` by default. Select ROS 2 Lyrical with
`kas/include/ros-distro-lyrical.yml` through the wrapper:

```bash
SAHA_ROS_DISTRO=lyrical ./scripts/saha-build orin-nx-16g-p3768
```

Home Assistant defaults to enabled. Use `SAHA_HOMEASSISTANT=0` to omit it;
see the shared [Home Assistant instructions](../../README.md#home-assistant-container).

## Output

For `orin-nx-16g-p3768`, the current tegraflash archive is emitted at:

```text
build/orin-nx-16g-p3768/tmp/deploy/images/p3768-0000-p3767-0000/saha-image-robot-p3768-0000-p3767-0000.rootfs.tegraflash-tar.zst
```

For non-default ROS distros, use the distro-specific build directory. For example, `SAHA_ROS_DISTRO=lyrical` emits the Orin NX archive under:

```text
build/orin-nx-16g-p3768-ros-lyrical/tmp/deploy/images/p3768-0000-p3767-0000/saha-image-robot-p3768-0000-p3767-0000.rootfs.tegraflash-tar.zst
```

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

## Network policy

NetworkManager manages WiFi only. USB gadget networking (`l4tbr0`,
`192.168.55.1`) stays on systemd-networkd. See the shared
[WiFi commands](../../README.md#device-networking).

## Image scope

The supported image target is `saha-image-robot`. On Jetson it is layered on the reusable `saha-image-base` recipe and includes the Jetson BSP base, CUDA runtime libraries, OpenSSH bring-up access, USB device-mode networking support, NetworkManager with `nmcli` for WiFi, the configured ROS 2 runtime and CLI tools, and by default Docker with the official Home Assistant container launcher.

The image does not include CUDA samples or Jetson GPU container runtime tooling. Add `nvidia-container-toolkit` later through an optional image or kas include if GPU-backed containers are required; OE4T R39.2 removed the old `nvidia-docker` recipe.

## Legacy migration

The old `resources/*.repos`, `scripts/init.sh`, `setup-env`, `scripts-setup/`, local machine templates, and Xavier NX / `rolling-nx` support have been removed. The supported path is Docker plus kas through `scripts/saha-build`.
