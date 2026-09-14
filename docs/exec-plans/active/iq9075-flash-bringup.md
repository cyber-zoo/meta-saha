# IQ-9075 Saha flash and hardware bring-up

## Authorization and objective

On 2026-09-14 the user explicitly requested flashing and debugging the
connected IQ-9075 EVK. Install the already built Saha image, inspect the UART
boot, and iterate on required fixes using Docker/kas and Conventional Commits.
Keep raw backups, credentials, build output, and UART/QDL logs out of Git.

## Baseline

- Board: WNC IQ-9075 EVK, UART bridge serial `NNPMQ0760003`.
- Ubuntu model: `Qualcomm Technologies, Inc. Addons IQ 9075 EVK`;
  compatibles include `qcom,qcs9075` and `qcom,sa8775p`.
- Storage: Micron 128 GB UFS, LUN0 exposed as `/dev/sdb` in Ubuntu;
  do not confuse Linux disk names with Firehose LUN numbers.
- Original OS: Ubuntu 24.04.4 / `6.8.0-1080-qcom`.
- Working UART: existing tio shared socket `/tmp/project-uart.sock`.
- Working ADB: USB-only root service from commit `c0acbf8`.
- Initial Saha package: `saha-image-robot-iq-9075-evk.rootfs-20260904122818.qcomflash`
  under `build/iq-9075-evk/tmp/deploy/images/iq-9075-evk/`.
  This is the HA-disabled base image, containing ROS 2 Jazzy.

## Sequence

1. Validate package and exact target, then perform QDL dry-run.
2. Preserve root filesystem files, EFI/persist, non-root UFS LUNs, and GPT
   layout in `build/hardware/iq9075-20260914/preflash/` (mode 0700).
   The root file backup is live, not an application-consistent block snapshot.
3. Request `systemctl --reboot-argument=edl reboot` through ADB. Require
   `05c6:9008` before selecting this device explicitly with QDL.
4. Flash the checked package with the supplied Firehose programmer and
   explicit rawprogram0..5 / patch0..5 lists. Never provision UFS or write
   unrelated host disks. Preserve the QDL log.
5. Inspect complete UART startup and verify hostname, kernel/rootfs, network,
   ADB and ROS 2. Fix required metadata, build in Docker/kas, and retest.

## Recovery

Retain the original UFS boot LUNs and EFI/persist images together with their
partition table and filesystem backup. If the new OS does not start, use
UART boot diagnostics and EDL to restore or repair the identified partitions.
Do not infer success merely from QDL completion or an ADB disconnect.

## Acceptance

- Saha reaches a usable Linux shell after the flash.
- Hardware identity and image version are recorded with UART/QDL evidence.
- Debug access works and boot/network/ROS smoke results are explicit.
- Any unresolved hardware limitations are distinguished from validated paths.
