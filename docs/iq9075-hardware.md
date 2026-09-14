# IQ-9075 EVK hardware bring-up

## Scope and access

The user authorized flashing the connected WNC IQ-9075 EVK on 2026-09-14.
Builds still use Docker/kas; host `adb`, `qdl`, and Alpaca control are separate
hardware operations. Never flash as part of a build/test wrapper.

The September 14 bring-up uses the HA-disabled Saha image with ROS 2 Jazzy:

```sh
SAHA_HOMEASSISTANT=0 ./scripts/saha-build iq-9075-evk
```

Native ADB is now packaged by Yocto. Shared `saha-usb-adb` owns the gadget
lifecycle; `meta-qcom-saha` selects USB-C UDC `a600000.usb` and its required
kernel modules. The separate Ubuntu support bundle is not installed in Saha.

With one USB ADB board connected:

```sh
adb devices -l
adb -d shell
adb -d shell 'id; uname -a; systemctl --failed --no-pager'
adb -d shell 'journalctl -u saha-usb-adb -b --no-pager'
adb -d push ./file /tmp/file
adb -d pull /tmp/file ./file.from-evk
```

With multiple boards, use `-s SERIAL` instead of `-d`. ADB serial is SHA-256
of `/etc/machine-id`: stable across reboot, but can change after reflashing
rootfs. USB ID is `18d1:0100`, product `IQ-9075 Saha ADB`. UART remains usable
through the existing tio socket `/tmp/project-uart.sock`; do not open a second
reader on its serial device.

This is **unauthenticated root access over physical USB**, suitable for this
development EVK, not a production security policy. No TCP ADB listener is
enabled. The service explicitly sets `User=root` so shells receive the home
directory needed by ROS logging.

## ROS and network checks

After entering the shell:

```sh
. /opt/ros/jazzy/setup.sh
ros2 --help
ros2 topic echo /saha_bringup std_msgs/msg/String --once
```

In another host terminal:

```sh
adb -d shell '. /opt/ros/jazzy/setup.sh; ros2 topic pub --once /saha_bringup std_msgs/msg/String "{data: iq9075-adb-ok}"'
```

The subscriber must print the matching payload. Run bounded waits on the host
if automating this test: this minimal image does not include `timeout`.

```sh
adb -d shell 'ip -br address; ip route; nmcli --colors no device status'
adb -d shell 'df -h /; cat /sys/kernel/debug/devices_deferred'
```

WiFi needs `kernel-module-pwrseq-pcie-m2` to power the slot before PCIe/ath11k
can probe. Ethernet needs `kernel-module-at24` for the EEPROM-backed MAC and
`kernel-module-qca808x` for the QCA8081 PHY. The generic PHY fallback cannot
validate the board's 2500BASE-X interface. Root ext4 uses `x-systemd.growfs`
to occupy the expanded UFS partition (about 107 GiB on this board).

WiFi credentials were restored from a private local backup, not embedded in
the image or committed. Flashing rootfs removes those local settings.

## Enter Fastboot through ADB (verified)

This reboots the EVK and stops applications:

```sh
adb -d shell 'systemctl --reboot-argument=bootloader reboot'
fastboot devices -l
# Return to Saha without writing any partition:
fastboot -s 57dc18d6 reboot
adb -d wait-for-device
```

The test board enumerated as `57dc18d6`; UART reported Android Fastboot 0.4.
Both entering Fastboot from ADB and returning to Saha were tested. Select your
actual serial if using another board. This session's partition writes used
QDL; Fastboot mode entry/exit does not imply every Fastboot flash operation
has been validated. Do not use `flashall`, unlock, erase, or repartition as
part of a connectivity test.

## Direct software EDL (not working on Saha)

Leaving Linux interrupts all applications. This command worked on the
original Ubuntu firmware/kernel combination, but **currently hangs after
shutdown on the pinned Saha combination**. Do not use it as the normal
Saha flashing path; use the verified Alpaca recovery below. The failing
command was `adb -d shell 'systemctl --reboot-argument=edl reboot'`.

An ADB disconnect alone is not success. Require Qualcomm EDL `05c6:9008`
and the intended chip serial before QDL. The test board reports `57DC18D6`;
this is different from its ADB and UART-bridge serials.

The upstream DT's EDL `<0 1>` means reset type 0, cookie 1, and is consistent
with both the earlier Qualcomm PSCI implementation and the current driver.
An experimental cell swap was disproven on hardware (it rebooted normally)
and reverted. Do not swap the cells or claim an ABI correction. The changed
kernel/firmware combination needs further investigation: Ubuntu reported
SMCCC 1.3, Saha reports SMCCC 1.1. This difference is evidence, not proof of
which component is responsible.

Use `adb shell` with Linux `systemctl`, not Android's `adb reboot edl`.
Do not change crash-dump policy to manufacture an EDL transition.

## Alpaca recovery

If Linux is inaccessible, official
[pytactl](https://github.com/qualcomm/pytactl) can control the connected
Alpaca bridge. Use a dedicated host virtualenv and the official
[TAC configurations](https://github.com/qualcomm/qcom-test-automation-controller).
Verified tool/config revisions are:

- pytactl: `e1cb399c117bfe000cafc5b79f44702754612e95`.
- TAC: `572e727ec2784c300aab1d9aa0bcac7b1c08baf2`.
- Descriptor: `ALPACA-LITE FOR RB8 IQ-9075-EVK`.
- Exact config: `TAC_FTDI_39.tcnf`, selected via `devicelist.json`.

After installing those tools/configs, select the physical bridge explicitly:

```sh
pytactl list
sudo pytactl oneshot bootToEDL --serial NNPMQ0760003 \
  --tac-config-path /path/to/tac/configurations
sudo qdl list
```

This performs the board's power/EDL sequence, not a flash. Its config controls
GPIO buses C/D and leaves tio's UART bus B alone. Never substitute a generic
FTDI GPIO map. To return from EDL without writing storage, the same tool's
`reset` command power-cycles this board with the download pins released.

## Flash and recovery data

Select an immutable, timestamped `.qcomflash` directory, inspect its XML,
validate the image hash and board identity, then run QDL dry-run first.
For this provisioned board, the initial full flash used the package's
`prog_firehose_ddr.elf`, explicit `rawprogram0.xml` through `rawprogram5.xml`,
and `patch0.xml` through `patch5.xml`, with `--storage=ufs` and
`--serial=57DC18D6`. Do not add provisioning commands.

Subsequent EFI/rootfs-only updates use `rawprogram0.xml patch0.xml` after
confirming those files target LUN0. This overwrites EFI/rootfs and updates
the LUN0 GPT; it does not preserve rootfs settings. Retain QDL/UART logs and
wait for a real Linux boot before declaring success.

**A DT change also requires updating the independent device-tree partitions.**
This boot chain consumes the FIT/FAT `dtb.bin` from `dtb_a`/`dtb_b` in LUN4;
the new DT is not activated by replacing EFI/rootfs alone. For the verified
existing layout, from the selected qcomflash directory and with the EVK in EDL:

```sh
sudo qdl --dry-run --storage=ufs prog_firehose_ddr.elf \
  write 4/dtb_a dtb.bin write 4/dtb_b dtb.bin
sudo qdl --serial=57DC18D6 --storage=ufs prog_firehose_ddr.elf \
  write 4/dtb_a dtb.bin write 4/dtb_b dtb.bin
```

QDL resolves those names from the target GPT. This writes only the two DT
images, not all of LUN4. After reboot, inspect the *running* DT properties in
`/sys/firmware/devicetree/base/psci/reboot-mode/`; checking deploy DTBs alone
would miss an unupdated DT partition.

Private local backups are under
`build/hardware/iq9075-20260914/preflash/` (parent mode 0700):

- Ubuntu root file archive (live backup, not an application-consistent image).
- Complete compressed raw UFS LUN1..7 images.
- LUN0 EFI/persist images, GPT backup, and sfdisk layout.
- Private NetworkManager/netplan archive and SHA-256 checksums.

The Ubuntu root archive passed gzip integrity and matching board/host SHA-256:
`6dcbf0bdf713ed4ef2010602607ce061ac769d9a36270c36b11b825f2b7e913f`.
Do not delete these backups or commit their credentials/binaries. Restore
only after mapping Firehose LUNs to the recorded layout; Linux `/dev/sdX`
names differ between Ubuntu and Saha.

## Validation limits

USB root shell, ADB push/pull checksums, normal reboot persistence, WiFi DHCP
and host ping, and ROS 2 topic delivery passed during bring-up. Ethernet PHY
binding passed; a cable/link throughput test is still needed. Audio codec
and PMIC ADC suppliers remain deferred. Camera, GPU/NPU workloads, audio,
and the optional Home Assistant image were not validated in this session.

Final retained artifact:
`build/hardware/iq9075-20260914/validated-image/saha-image-robot-iq-9075-evk.rootfs-20260914072915.qcomflash.tar.gz`
(496 MiB), SHA-256
`2d21e4ab08b47a97a769de74dd07354217de376f99fa2162b085b380e4f11f5f`.
Its directory includes the manifest and `SHA256SUMS`, outside BitBake's
cleanable deploy output. Do not use the separately retained, rejected
`experimental-dt-swap/` package.
