# IQ-9075 Saha flash and hardware bring-up

Status: base-image flash and debug bring-up completed; direct software EDL
and extended peripheral coverage are tracked in the backlog.

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

## Progress on 2026-09-14

- Preserved Ubuntu root files, complete UFS LUN1..7, LUN0 EFI/persist/GPT,
  and private network profiles before any write; gzip and SHA-256 checks passed.
- Initial full QDL flash succeeded. Saha reached root UART shell with kernel
  `6.18.37-gdc0f4d4280a7-dirty`; no failed systemd units.
- Initial image omitted FunctionFS/ADB, M.2 power sequencing, and EEPROM
  suppliers. Commit `9c219d2` adds native shared ADB policy, the runtime
  packages, and ext4 growth. Docker/kas image build passed (14,787 tasks).
- Updated EFI/rootfs from `rootfs-20260914064959.qcomflash`. Native USB ADB,
  WiFi DHCP (`10.30.0.222`), host ping, and 106.8 GiB rootfs growth passed.
- Added missing QCA8081 PHY driver after observing generic PHY 2500BASE-X
  validation failure. Runtime load bound the correct PHY; no cable carrier.
- Explicit `User=root` provides HOME/LOGNAME to ADB shells; ROS logging and
  two-process std_msgs topic delivery then passed. ADB push/pull SHA-256 and
  normal reboot persistence also passed.
- Saha EDL reboot hung. Recovered remotely with official pytactl and exact
  TAC_FTDI_39 config, bridge `NNPMQ0760003`; QDL serial `57DC18D6` reappeared.
- Commit `1c0bb43` added PHY/login fixes and an experimental DT argument swap.
  Hardware disproved the swap: after explicitly updating LUN4 dtb_a/dtb_b,
  the request rebooted normally, not into EDL. Reviewing the earlier driver
  confirmed the upstream cells were already correct. Commit `77d71ce`
  reverts only the disproven DT change and retains the runtime fixes.
- The final upstream-DT build passed all 14,787 tasks (14,740 reused).
  Package: `rootfs-20260914072915.qcomflash.tar.gz`, SHA-256
  `2d21e4ab08b47a97a769de74dd07354217de376f99fa2162b085b380e4f11f5f`.
  A separate copy and manifest/checksums are retained in
  `build/hardware/iq9075-20260914/validated-image/`; the rejected experiment
  is preserved separately under `experimental-dt-swap/`, not a release image.
- Final EFI/rootfs and both DT partitions were flashed from that package.
  The running DT has the original upstream cells. Native ADB/root login,
  file transfer hashes, ROS `iq9075-final-ok` topic delivery, WiFi DHCP/ping,
  rootfs growth, and zero failed systemd units passed on the final image.
- `adb shell 'systemctl --reboot-argument=bootloader reboot'` successfully
  entered Fastboot (`57dc18d6`, UART Fastboot 0.4). `fastboot reboot` returned
  to Saha and ADB. Direct software EDL remains unresolved; Alpaca EDL is the
  verified QDL recovery path. No Fastboot partition write was performed.
- Docker/kas full image build, Docker framework/safety tests, Docker
  ShellCheck, and whitespace checks passed. Hardware logs are retained under
  `build/hardware/iq9075-20260914/`, outside Git.

## Remaining peripheral scope

- Ethernet PHY binding works; physical link/throughput has not been tested.
- Audio codec and PMIC ADC suppliers remain deferred. In this pinned kernel,
  `CONFIG_QCOM_SPMI_ADC5_GEN3` is disabled. Do not claim thermal/peripheral
  coverage or perform stress tests based solely on successful boot.
- Camera/GPU/NPU workloads and Home Assistant are not part of this smoke pass.
- See [hardware runbook](../../iq9075-hardware.md) for access and recovery.

## Bug analysis: boot-time contracts missing from build-only coverage

### 1. Root cause category

Cross-layer contracts and test-coverage gaps: image packages omitted kernel
suppliers and a root service lacked the login environment expected by ROS.
EDL behavior changed across the kernel/firmware combination. A guessed DT
ABI explanation was disproven and reverted. All these failures can coexist
with a successful BitBake image build.

### 2. Why initial checks were insufficient

Presence of ath11k/stmmac did not imply their EEPROM/power/PHY suppliers were
installed. Presence of mode-edl did not prove that firmware would execute the
requested reset. `ros2 --help` did not exercise logging or DDS. ADB shell exit
status on this older daemon did not reliably expose target command failures.

### 3. Prevention mechanisms

| Priority | Mechanism | Status |
| --- | --- | --- |
| P0 | Image tests require ADB, M.2, EEPROM and PHY modules | Done |
| P0 | Compare actual reset arguments and require EDL enumeration | Disproven patch reverted; software EDL unresolved |
| P1 | Explicit ADB User and ROS topic payload check | Passed on running Saha |
| P1 | Original storage backup and exact Alpaca recovery mapping | Verified and documented |

### 4. Systematic expansion

Other BSPs must select their own UDC/supplier packages rather than copying
IQ-9075 addresses. Do not change other Qualcomm DT reset cells based on the
rejected hypothesis; compare actual driver/firmware arguments first. Remaining
ADC/audio dependencies are tracked separately, not masked by boot success.

### 5. Knowledge capture

Updated the hardware runbook and workspace QCOM build spec with executable
contracts, failure signatures, and acceptance checks. No generated spec
template tree exists in this layer repository to synchronize.
