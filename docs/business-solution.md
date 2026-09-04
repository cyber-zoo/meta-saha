# Business Solution

## Positioning

`meta-saha` provides reproducible, robot-oriented Yocto images and a
containerized build experience for supported edge-computing boards. It is not
a replacement for a silicon vendor's BSP, a generic Yocto distribution, or an
unattended device-flashing service.

## Users and their jobs

| User | Core job supported by the repository |
| --- | --- |
| Robotics platform developer | Produce a repeatable system image without installing kas, BitBake, or Yocto host packages locally. |
| System integrator | Select a supported board alias, include the Saha robot stack, and locate generated images and RPMs. |
| Bring-up engineer | Validate a build before hardware is available, then use documented vendor-appropriate flashing steps when hardware is connected. |
| RDK X5 accelerator integrator | Build an isolated optional accelerator image and run its non-actuating BPU smoke check on hardware. |
| Qualcomm IQ-9075 integrator | Build the standard IQ-9075 EVK image and hand its upstream-compatible `qcomflash` package to a later hardware bring-up step. |

## Current, evidenced capabilities

- Docker + kas is the documented build path; build, downloads, and sstate
  directories persist on the host for reuse.
- Jetson Orin/Thor targets use a Wrynose/OE4T graph, while RDK X5 has its own
  pinned Wrynose graph and mounts `meta-d-robotics` read-only.
- All current targets build `saha-image-robot`, with a common static hostname
  of `sahaWorld`.
- Jetson builds can select ROS 2 Jazzy (default) or Lyrical. Jetson and
  IQ-9075 can opt into a preloaded Home Assistant container; RDK X5 deliberately
  accepts only Jazzy and does not enable that packagegroup by default.
- IQ-9075 uses the standard upstream `iq-9075-evk` machine, a pinned Qualcomm
  `meta-qcom` Wrynose graph, and the same Saha image/application packagegroups
  as the other supported platforms.
- RDK X5 has an optional BPU/runtime image and a smoke program that validates
  an inference path without commanding a robot.
- The RDK X5 TF-card helper requires an explicit image and removable whole
  disk, performs preflight checks, and requires typed confirmation before a
  real write.

## Typical scenarios

1. A developer builds a Jetson Orin image through `scripts/saha-build` and
   hands the resulting tegraflash archive to a separate bring-up step.
2. A team builds an RDK X5 WIC image with an externally supplied vendor BSP
   checkout, then uses the guarded helper to prepare a removable TF card.
3. A robot application team switches a Jetson image from the default Jazzy
   graph to the Lyrical graph without creating a second image recipe.
4. An RDK X5 team opts into the accelerator graph only when its BPU and
   supported camera/runtime packages are needed.

The repository documents these flows. Broader industrial use cases, customer
segments, commercial model, and success metrics are not evidenced in the
repository and remain **to be supplied by the business owner**.

## End-to-end flow

1. The user chooses a supported target alias and optional, validated `SAHA_*`
   settings.
2. A wrapper composes the target-specific kas configuration and starts the
   Docker builder with persistent caches mounted.
3. kas resolves the appropriate vendor graph and BitBake builds
   `saha-image-robot`.
4. The developer collects the image or RPM artifacts under the target build
   directory.
5. Only after the build is verified and hardware is available does a human run
   the documented vendor-specific flash procedure. IQ-9075 QDL/EDL is a later
   handoff and is not executed by this repository's build workflow.

## Boundaries and risks

- A successful parse or package build does not prove device boot, peripherals,
  accelerator behavior, or field reliability.
- Vendor BSP downloads, closed source components, and hardware-specific flash
  tooling can be required outside this repository.
- Full Yocto builds are network-, time-, and storage-intensive.
- Qualcomm firmware/boot artifacts may require vendor access even though the
  machine and repository revisions are pinned; a successful kas parse does not
  guarantee that a full package build can fetch every proprietary artifact.
