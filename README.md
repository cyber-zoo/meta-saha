# meta-saha

`meta-saha` is a Yocto Project distro layer and build framework for robot
systems. It provides a consistent robot image and reusable application stack
across hardware platforms, sharing common configuration and software while
keeping vendor BSPs and board-specific policy in separate layers.

The primary workflow builds `saha-image-robot` with kas inside Docker. Target
configurations select the hardware integration; shared layers provide ROS 2,
WiFi tooling, and optional Home Assistant support. The host does not need kas,
bitbake, vcstool, or Yocto build packages installed.

## Supported targets

| Target alias | `MACHINE` | Hardware guide | Baseline |
| --- | --- | --- | --- |
| `orin-nx-16g-p3768` | `p3768-0000-p3767-0000` | [Jetson Orin NX 16GB / P3768](docs/hardware/jetson.md) | Yocto 6.0 Wrynose; OE4T meta-tegra Wrynose; JetPack 7.2 / L4T R39.2.0 |
| `agx-thor-devkit` | `jetson-agx-thor-devkit` | [Jetson AGX Thor devkit](docs/hardware/jetson.md) | Yocto 6.0 Wrynose; OE4T meta-tegra Wrynose; JetPack 7.2 / L4T R39.2.0 |
| `agx-orin-devkit` | `jetson-agx-orin-devkit` | [Jetson AGX Orin devkit](docs/hardware/jetson.md) | Yocto 6.0 Wrynose; OE4T meta-tegra Wrynose; JetPack 7.2 / L4T R39.2.0 |
| `rdk-x5` | `rdk-x5` | [D-Robotics RDK X5](docs/hardware/rdk-x5.md) | Pinned Wrynose; RDKOS 3.5.0 / SDK 1.1.1; Linux 6.1.83 |
| `iq-9075-evk` | `iq-9075-evk` | [Qualcomm Dragonwing IQ-9075 EVK](docs/hardware/iq9075.md) | Pinned Wrynose / Qualcomm meta-qcom; ROS 2 Jazzy |

List targets with:

```bash
./scripts/saha-targets
```

See [supported hardware](docs/hardware/README.md) for platform prerequisites,
image variants, artifact formats, flashing, and validation limits.

## Prerequisites

- Docker with permission to run containers as your user.
- Enough disk space for a Yocto build. A first build can consume hundreds of GB
  across build output, downloads, and sstate cache.
- Network access to fetch upstream sources and any vendor artifacts required
  by the selected [hardware guide](docs/hardware/README.md).

No host-side Yocto package setup is part of the primary build path.

## Build

From the `meta-saha` repository root, select an alias from Supported targets:

```bash
./scripts/saha-build <target>
```

For example:

```bash
./scripts/saha-build orin-nx-16g-p3768
```

The script builds the Docker builder image, mounts persistent cache
directories, then runs the target-specific kas graph. Follow the selected
[hardware guide](docs/hardware/README.md) for required BSP inputs and supported
options; not every platform supports every software variant.

## Output and caches

Default host paths:

| Path | Purpose |
| --- | --- |
| `build/<target>/` | Default target-specific kas/bitbake build directory for `SAHA_ROS_DISTRO=jazzy` |
| `build/<target>-ros-<distro>/` | Target-specific kas/bitbake build directory for non-default ROS distros such as `lyrical` |
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

Hardware-specific image formats and variant directories are documented in
the [hardware guides](docs/hardware/README.md). Building produces artifacts;
flashing is a separate, explicitly selected operation.

Override cache/build locations with environment variables:

```bash
SAHA_BUILD_DIR=/data/yocto/build-orin \
SAHA_DOWNLOADS_DIR=/data/yocto/downloads \
SAHA_SSTATE_DIR=/data/yocto/sstate-cache \
./scripts/saha-build orin-nx-16g-p3768
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

`saha-image-robot` can include Docker, the official Home Assistant container
launcher, and a preloaded Home Assistant container image. Platform defaults
are listed in the [hardware guides](docs/hardware/README.md). Disable that
stack at build time with:

```bash
SAHA_HOMEASSISTANT=0 ./scripts/saha-build orin-nx-16g-p3768
```

This omits `docker`, the Home Assistant launcher, the preloaded tarball, and the extra rootfs space reserved for it. ROS 2, USB gadget networking, and WiFi support are unaffected.

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

The supported targets need the `linux/arm64` image. An amd64-only local image is skipped automatically.

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

Select `SAHA_ROS_DISTRO` only from the combinations supported by the selected
[hardware guide](docs/hardware/README.md). The default is `jazzy`; unsupported
combinations are rejected before Docker starts.

After flashing, initialize the ROS environment with:

```bash
source /opt/ros/<distro>/setup.sh
ros2 --help
```

## Device networking

All Saha robot images use `sahaWorld` as the default static hostname.
NetworkManager with `nmcli` manages WiFi only; wired and USB networking remain
under the platform policy documented in the [hardware guides](docs/hardware/README.md).

```bash
nmcli dev wifi list
nmcli dev wifi connect "YOUR_SSID" password "YOUR_PASSWORD"
nmcli dev status
ip addr show wlan0
```

If the WiFi interface name is not `wlan0`, use the name shown by `nmcli dev status`.

## Add a target

1. Confirm the machine exists in the chosen vendor BSP and establish a compatible
   repository baseline.
2. Reuse common software from `meta-saha-common`; keep vendor integration in a
   separate BSP-family layer and reusable kas includes.
3. Add the alias and machine mapping to `scripts/saha-lib`, then add
   `kas/targets/<alias>.yml` with the matching `machine` and graph.
4. Add focused target/configuration tests, a hardware guide under
   `docs/hardware/`, and a Supported targets row with its baseline and guide link.
5. Run the framework tests and Docker/kas configuration validation:

```bash
bash tests/test-build-framework.sh
./scripts/saha-validate <alias>
```

## Removed legacy flow

The old vcstool/manual-symlink setup has been removed. The supported path is
Docker plus kas through `scripts/saha-build`. See the
[Jetson migration notes](docs/hardware/jetson.md#legacy-migration) for the
removed entry points and target support.

## License

This project is open sourced under Apache 2.0 License.

The source code originally forked from OE4T `tegra-demo-distro` is under the MIT License; see `docs/licenses/OE4T.license`.
