# Architecture

## Repository boundaries

```text
user
  -> scripts/saha-build or scripts/saha-shell
       -> scripts/saha-lib (aliases, options, paths, validation)
       -> Docker builder
            -> kas target graph
                 -> BitBake + vendor/OpenEmbedded layers
                      -> saha-image-robot artifacts
```

| Area | Responsibility |
| --- | --- |
| `scripts/` | Stable developer-facing commands, target/option validation, Docker invocation, and safe flash helpers. |
| `docker/` | The x86_64 Yocto builder image and its host dependencies. |
| `kas/targets/` | Small per-board entry points that select a machine and the appropriate graph. |
| `kas/include/` | Reusable repository graphs, image policy, ROS variants, and optional feature overlays. |
| `saha-layers/meta-saha-common/` | Platform-neutral Saha image include, packagegroups, hostname/SSH bring-up policy, and optional Home Assistant container stack. |
| `saha-layers/meta-tegra-saha/` | Jetson-specific Saha distro, images, packagegroups, CUDA, peripherals, and compatibility append files. |
| `saha-layers/meta-tegra-support/` | OE4T support classes and Jetson compatibility metadata. |
| `saha-layers/meta-rdk-x5-saha/` | RDK X5-specific distro, images, packagegroups, networking, and accelerator integration. |
| `saha-layers/meta-qcom-saha/` | Qualcomm Dragonwing IQ-9075 distro/image composition; the upstream `meta-qcom` layer owns BSP and flash metadata. |
| `tests/` | Executable contracts for wrappers, image options, and RDK X5 flash safety. |

## Platform graphs

Jetson targets compose a Wrynose graph containing OpenEmbedded, OE4T
`meta-tegra`, local Jetson Saha layers, and a ROS overlay. Home Assistant is a
separate opt-in kas include. The target alias, vendor `MACHINE`, and user
description have one source of truth in `scripts/saha-lib`.

RDK X5 deliberately does not inherit the Tegra graph. Its target composes a
pinned RDK-compatible graph and requires an external `meta-d-robotics`
checkout mounted read-only. The accelerator include is optional and writes to
a separate build directory so it cannot overwrite the base image.

IQ-9075 likewise does not inherit either existing BSP graph. Its target
composes pinned OpenEmbedded, Linux-firmware mixin, meta-virtualization,
meta-ROS Jazzy, and Qualcomm `meta-qcom` Wrynose repositories, then adds the
local common and `meta-qcom-saha` layers. The upstream `iq-9075-evk` machine
selects the QCS9100-family kernel, firmware, device trees and UFS partition
metadata; Saha contributes only the shared image/application policy.

Future vendor support must follow the same separation: use a dedicated BSP
graph and Saha layer for vendor-specific metadata, then share only the
application/image contracts proven compatible across platforms.

## Dependency direction

```text
target alias -> kas target -> reusable kas include -> vendor/local layers
                                              -> image/packagegroups
wrapper scripts -> Docker -> kas target
tests -> public wrapper and metadata contracts
```

- Wrapper scripts may select kas overlays; metadata must not depend on host
  shell state other than documented variables and mounted paths.
- A generic application packagegroup may be shared only when every referenced
  package exists in each selected BSP graph.
- Vendor-specific kernel, firmware, boot, USB-gadget, accelerator, and flash
  behavior stays in that vendor's layer or documented procedure.
- Build output and caches flow out of the container into mounted host paths;
  they do not flow back into versioned source.

## Image and artifact flow

`saha-image-robot` is the supported developer-facing image name. BitBake emits
vendor-specific artifacts beneath `build/<target>/tmp/deploy/images/<machine>/`
and RPMs beneath `build/<target>/tmp/deploy/rpm/`. Artifact format and flashing
procedure are hardware-specific; the build framework does not turn them into a
single universal flash interface.
