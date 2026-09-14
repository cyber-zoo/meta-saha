# IQ-9075 Ubuntu ADB bring-up

## Goal

Restore USB `adb shell` on the connected IQ-9075 EVK, preserve its working
tio console, and document a checked path toward later EDL entry and debugging.
Do not flash or reboot the board as part of this change.

## Observed baseline (2026-09-14)

- The board runs Ubuntu 24.04.4, kernel `6.8.0-1080-qcom`, not Saha/Yocto.
- Host USB enumeration contains the FT4232H UART bridge but no ADB interface.
- No device-side `adbd` binary or service is installed; Noble has no `adbd`
  package candidate. The host `adb` client is already available.
- ConfigFS/FunctionFS kernel support exists; no gadget was configured.
- UDCs: `a400000.usb`, `a600000.usb`, `a800000.usb`.
- Existing tio provides `/tmp/project-uart.sock` and an authenticated sudo
  session. Use that socket instead of opening the UART a second time.

## Implementation and rollback

1. Inspect official Linux adbd packaging, dependencies, and USB controller.
2. Extract pinned Debian ARM64 adbd and Android libraries under
   `/opt/saha-adbd`, without adding an APT repository or replacing Ubuntu
   libraries. Retain licenses and package hashes.
3. Install an explicitly selected ConfigFS gadget and systemd service.
   Require FunctionFS before starting adbd to prevent TCP fallback.
4. Verify host enumeration, shell identity, file transfer, and service restart.
5. Check EDL prerequisites read-only; document what remains untested.

Rollback first stops/disables the new service, which removes only its own
gadget. The isolated runtime and two installed service/helper files can then
be removed. Existing UART, boot configuration, and root filesystem remain.

## Validation

Run shell syntax and systemd unit checks, then actual USB ADB checks. No
Yocto metadata changes are planned for the Ubuntu runtime repair; any later
Saha image change must use the existing Docker/kas build path.

## Outcome

- USB-C UDC `a600000.usb` enumerated as `18d1:0100`; root `adb shell`,
  push/hash verification, pull, and service restart/reconnect passed.
- `saha-adbd.service` is enabled. Cold boot is not tested.
- The runtime and licenses are isolated in `/opt/saha-adbd`; no TCP listener.
- EDL is represented by `/psci/mode-edl = <0 1>`, with RESET2 mode parsing
  present in the running kernel. Documented systemd reboot argument without
  executing it. No reboot, EDL transition, or flash took place.
- Reproduction and rollback are in `support/iq9075-ubuntu-adb/README.md`.
- Runtime packaging passed in `meta-saha-yocto-builder:wrynose`, including
  every pinned package hash, archive integrity, and refusal to overwrite an
  existing bundle. Final output: `build/support/iq9075-adb/bundle/`.
- Shell syntax, Docker ShellCheck, existing build-framework and RDK flash
  safety tests passed. Final deployed helper hash matches the source.
