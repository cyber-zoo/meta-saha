# Microduck on Saha

The Radxa ZERO 3W and Orange Pi Zero 3W work targets a shared, ROS-free
`saha-image-robot` with the official stable Microduck runtime. BSP layers own
kernel, boot, firmware and device trees; Saha owns runtime dependencies,
services and application configuration. Existing Jetson/RDK/Qualcomm images
keep their ROS selection.

## Incremental validation

The common layer loads its ROS packagegroup through `BBFILES_DYNAMIC` only
when `ros2-layer` is present. `kas/check/common-without-ros.yml` checks the
common layer against pinned Wrynose and meta-openembedded, without fetching
meta-ROS or a vendor layer. It selects `core-image-minimal` for a metadata
check and is not a Microduck image build.

2026-10-01: Docker kas 5.5 / BitBake parsed all 2,981 recipes with zero
errors in this graph. The existing build-framework and RDK flash safety
regressions, Bash syntax and whitespace checks passed. The graph contains
no meta-ROS checkout; `packagegroup-saha-ros2` remains available to graphs
that register `ros2-layer`.

Every build claim records the command, source revisions and its actual level:
parse, package, image or hardware. Small Conventional Commits provide rollback
points. Revert consuming commits before changes to their dependencies.
