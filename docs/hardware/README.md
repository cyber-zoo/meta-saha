# Supported hardware

[Project README](../../README.md)

Choose a guide for platform prerequisites, software variants, image artifacts,
flashing, and first-boot access. Baselines and target aliases are maintained in
the root [Supported targets table](../../README.md#supported-targets).

| Hardware family | Target aliases | Guide |
| --- | --- | --- |
| NVIDIA Jetson | `orin-nx-16g-p3768`, `agx-thor-devkit`, `agx-orin-devkit` | [Build, flash, and first boot](jetson.md) |
| D-Robotics RDK X5 | `rdk-x5` | [Base/accelerator builds and guarded TF-card flashing](rdk-x5.md) |
| Qualcomm Dragonwing IQ-9075 EVK | `iq-9075-evk` | [Build and image scope](iq9075.md); [ADB, flash, recovery, and validation limits](../iq9075-hardware.md) |

Build support does not imply every peripheral or software variant has been
validated on hardware. Consult the guide and its validation records before
flashing. Flashing is separate from building and requires an explicitly
identified device and image; no build or test wrapper performs a board flash.

Shared Docker/kas usage, cache configuration, ROS 2, Home Assistant, and WiFi
commands remain in the [project README](../../README.md).
