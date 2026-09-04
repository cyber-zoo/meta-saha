# meta-saha — Agent Working Guide

## What this repository is

`meta-saha` is a Yocto Project distro layer and reproducible build framework
for robot-oriented images. It supports NVIDIA Jetson, D-Robotics RDK X5, and
the Qualcomm Dragonwing IQ-9075 EVK; every supported build runs kas inside
Docker.

## Quick orientation

- **Repository root:** `meta-saha/`; run `pwd` before executing commands.
- **Stack:** Yocto Project 6.0 Wrynose, BitBake/OpenEmbedded metadata, kas,
  Docker, and Bash.
- **Primary image:** `saha-image-robot`.
- **Build entry point:** `./scripts/saha-build <target>`.
- **Qualcomm target:** `./scripts/saha-build iq-9075-evk` (ROS 2 Jazzy only).
- **List supported targets:** `./scripts/saha-targets`.
- **Focused checks:** `bash tests/test-build-framework.sh` and
  `bash tests/test-flash-rdk-x5.sh`.

For a real build, use a supported alias such as:

```bash
./scripts/saha-build orin-nx-16g-p3768
```

The first build needs substantial disk space and network access. Build output,
download, sstate, Docker, and third-party checkout directories are local
caches, not source files to edit or commit.

## Knowledge-base map

Read the relevant document before changing an area:

| Need | Read |
| --- | --- |
| Product intent, users, and boundaries | `docs/business-solution.md` |
| Layers, graphs, and build flow | `docs/ARCHITECTURE.md` |
| Naming, metadata, shell, and commit rules | `docs/CONVENTIONS.md` |
| Why the build graph is structured this way | `docs/TECH_DECISIONS.md` |
| Definition of done and validation | `docs/QUALITY.md` |
| Current implementation plans | `docs/exec-plans/active/` |
| Unscheduled work | `docs/exec-plans/backlog.md` |
| Known code-quality work | `docs/exec-plans/tech-debt-tracker.md` |

## Working rules

1. Keep the Docker + kas path as the primary build interface. Do not add a
   host-installed BitBake workflow.
2. Keep target aliases and their `MACHINE` mappings centralized in
   `scripts/saha-lib`; target kas files should contain platform selection, not
   duplicated application policy.
3. Reuse image/application intent where BSP compatibility permits, but keep
   vendor-specific layer graphs and flash procedures isolated.
4. Put cross-BSP packagegroups, image policy, hostname/SSH bring-up, and the
   optional Home Assistant stack in `saha-layers/meta-saha-common/`; keep
   CUDA, RDK BPU/networking, and Qualcomm kernel/firmware/partition metadata
   in their vendor layers.
5. Treat `build/`, `downloads/`, `sstate-cache/`, `repos/`, and
   `.docker-cache/` as generated or cached state. Do not hand-edit or commit
   their contents.
6. Use `SAHA_*` environment variables for documented build options. Validate
   bad combinations before Docker or BitBake starts.
7. Add or update focused shell tests whenever a wrapper, target mapping,
   image contract, or flash safety boundary changes.
8. Keep changes small and independently reversible. Commit completed steps
   with Conventional Commits (for example, `feat(qcom): ...`).
9. A flash command is a separate, destructive operation. Never invoke one
   against hardware or a block device without the user's explicit direction.

## Do not do these things

- Do not silently mix a Tegra, RDK X5, or future Qualcomm BSP graph.
- Do not claim a full image build or on-target validation unless it completed.
- Do not expose proxy credentials or other secrets in scripts, tests, logs, or
  documentation.
- Do not weaken the RDK X5 flash helper's explicit image/device/confirmation
  checks for convenience.
- Do not overwrite existing user changes or use destructive Git commands.
