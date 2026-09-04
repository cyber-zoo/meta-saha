# Technical Decisions

| Decision | Rationale and scope |
| --- | --- |
| Docker + kas is the primary entry point | Keeps the host free of kas, BitBake, and Yocto build-package setup, while mounting persistent downloads, sstate, and output caches. |
| Wrynose is the current Yocto baseline | The current Jetson framework targets Yocto Project 6.0 Wrynose with OE4T Wrynose. The RDK X5 graph also pins a Wrynose-compatible contract rather than relying on moving branch heads. |
| Vendor graphs stay separate | Tegra and RDK X5 have materially different BSP, kernel, firmware, and artifact contracts. Isolation prevents a board-specific dependency from accidentally altering another platform. |
| `saha-image-robot` is the primary image | The repository keeps a single developer-facing image intent and builds vendor-specific deliverables from it, rather than maintaining unrelated image targets for each application stack. |
| Application features use overlays/packagegroups | ROS distributions, Home Assistant, and RDK X5 accelerators are composed as optional kas includes or packagegroups so base image policy remains auditable and reversible. |
| ROS 2 Jazzy is default | Jazzy is the documented default. Lyrical is explicitly supported only for Jetson; RDK X5 rejects it to protect its independently verified graph. |
| RDK X5 accelerator output is isolated | `SAHA_X5_ACCELERATORS=1` selects a separate graph and build directory, so a BPU/runtime build cannot overwrite the base image result. |
| Flashing is not part of ordinary builds | Build artifacts are safe to create without hardware. Flashing has vendor-specific risk; the RDK helper enforces removable-media checks and confirmation, while Jetson instructions remain separate. |

## Pending decision: Qualcomm Dragonwing IQ-9075

The requested IQ-9075 platform must use a Qualcomm-specific layer graph rather
than adapting Tegra metadata. Initial research identifies `meta-qcom` as the
upstream OpenEmbedded layer and its `wrynose` branch as the Yocto 6.0 LTS
branch. Before a production target is declared supported, the implementation
must establish the exact EVK machine configuration, any proprietary firmware
or BSP access requirements, the image artifact format, and the EDL/QDL flash
procedure. These details are intentionally not guessed in shared metadata.

## Decisions requiring a maintainer or hardware confirmation

- Product-level target hardware: IQ-9075 EVK versus a module/carrier product.
- Which vendor firmware/boot packages may be fetched in a non-interactive
  Docker build and how credentials are supplied without committing them.
- On-target validation matrix for Ethernet, storage, camera, AI/NPU, and ROS
  middleware.
- Production security policy for development conveniences such as root login
  and preloaded containers.
