# IQ-9075 Ubuntu USB ADB repair

This is an on-device repair for Ubuntu 24.04 ARM64. It is not a Yocto recipe
and is not the ADB runtime installed in `saha-image-robot`. Continue to use
Docker/kas for Saha builds. On 2026-09-14 the EVK was backed up and flashed
with Saha; its native Yocto ADB is documented in the
[hardware runbook](../../docs/iq9075-hardware.md). This Ubuntu recovery bundle
now reuses the gadget helper from `meta-saha-common`.

## Diagnosis and verified state

The EVK running Ubuntu 24.04.4 / `6.8.0-1080-qcom` had no `adbd` binary,
service, or USB gadget. Host `adb devices` was empty, while tio worked through
the separate FT4232H UART bridge (`0403:6011`). USB-C was connected correctly.
Installing the host-side `adb` package on the board would not supply `adbd`.

The repair uses Debian's Linux `adbd` 34.0.5 and its Android libraries,
extracted into `/opt/saha-adbd`. It does not add Debian APT sources, install
foreign packages with dpkg, or replace Ubuntu system libraries. Other runtime
dependencies are provided by the board's existing Ubuntu packages; `ldd` was
checked on the board before starting the service.

The service selects USB-C UDC `a600000.usb` explicitly: choosing the first UDC
would incorrectly select `a400000.usb` on this kernel. Gadget ID is
`18d1:0100`, product `IQ-9075 Ubuntu ADB`. The serial is SHA-256 of the board's
`/etc/machine-id`, remaining stable across service restarts.

On 2026-09-14 the following passed on hardware:

- Host USB enumeration and `adb -d shell id`: `uid=0(root)`.
- UDC state `configured`; service active and enabled.
- Push of a file with matching SHA-256, and pull of `/etc/os-release`.
- Service restart via the existing tio socket followed by USB ADB reconnect.
- No adbd TCP listener on the board; systemd unit verification.

Later that day, Ubuntu's actual ADB-to-EDL transition also passed before the
authorized Saha flash. A cold boot of this Ubuntu repair was not tested.
Existing unrelated Aidlux unit warnings were not ADB failures.

## Daily use

With only this USB ADB device connected:

```sh
adb devices -l
adb -d shell
adb -d shell 'uname -a; systemctl --failed'
adb -d shell 'journalctl -u saha-adbd.service -n 50 --no-pager'
adb -d push ./file /tmp/file
adb -d pull /tmp/file ./file.from-evk
```

For multiple USB devices, replace `-d` with `-s SERIAL` from `adb devices -l`.
The existing tio console remains available as a recovery/debug channel.

This Linux adbd provides unauthenticated **root access over physical USB**.
That is intended for this development EVK. It is not a production access
policy. The service requires FunctionFS before adbd starts and removes
`ADBD_PORT` from its environment, avoiding the daemon's TCP fallback. Do not
enable TCP ADB on a shared network without a separate access-control design.

## Enter EDL through the Ubuntu adb shell

Read-only checks on this board found `/psci/mode-edl = <0 1>`,
`psci_init_system_reset2_modes` and `psci_reset_params` in the running kernel,
and systemd 255 acceptance of `--reboot-argument=edl`. These are the expected
PSCI vendor RESET2 prerequisites; Ubuntu-to-EDL was subsequently verified by
USB enumeration and QDL chip serial detection. This evidence applies to the
Ubuntu kernel, not automatically to another kernel's DT/reset implementation.

Only when ready to leave Ubuntu and enter flash mode, run:

```sh
adb -d shell 'systemctl --reboot-argument=edl reboot'
# On the host, after ADB disconnects:
lsusb -d 05c6:9008
```

The command reboots the EVK and interrupts applications. Success means the
host sees Qualcomm EDL `05c6:9008`; an ADB disconnect alone is not proof. QDL
flashing is a subsequent, separately authorized operation. Power-cycle to
return to Ubuntu if no flash has changed storage and no forced-EDL switch is
set.

Do not substitute `adb reboot edl`: this Debian daemon's reboot service calls
the Android path `/system/bin/reboot`, which does not exist on this Ubuntu
image. `adb shell` invokes Ubuntu's installed systemd command instead. Do not
change `qcom_scm.download_mode` to manufacture EDL: that parameter concerns
crash-dump policy, not this explicit PSCI EDL request.

## Reproduce the runtime bundle

From the repository root, package the pinned official binaries using the
existing Docker builder. This performs no compilation and no BitBake build:

```sh
mkdir -p build/support/iq9075-adb
docker run --rm --user "$(id -u):$(id -g)" \
  --mount "type=bind,src=$PWD,dst=/work/meta-saha" \
  --workdir /work/meta-saha meta-saha-yocto-builder:wrynose \
  bash support/iq9075-ubuntu-adb/prepare-runtime build/support/iq9075-adb/bundle
```

The output directory must not already exist. `packages.sha256` pins every
download; the output retains the original `.deb` packages, upstream notices,
and `bundle.sha256`. Transfer `runtime.tar.gz`, `saha-adb-gadget`,
`saha-adbd.service`, and `bundle.sha256` to an empty staging directory on the
EVK through an existing trusted connection. Then, **on the Ubuntu EVK**:

```sh
sha256sum -c bundle.sha256
# For a fresh installation; mkdir fails if a previous installation exists.
sudo mkdir /opt/saha-adbd
sudo tar -xzf runtime.tar.gz -C /opt/saha-adbd
LD_LIBRARY_PATH=/opt/saha-adbd/usr/lib/aarch64-linux-gnu/android \
  ldd /opt/saha-adbd/usr/lib/android-sdk/platform-tools/adbd
# Resolve any "not found" dependencies before proceeding.
sudo install -m 0755 saha-adb-gadget /usr/local/sbin/saha-adb-gadget
sudo install -m 0644 saha-adbd.service /etc/systemd/system/saha-adbd.service
sudo systemd-analyze verify /etc/systemd/system/saha-adbd.service
sudo systemctl daemon-reload
sudo systemctl enable --now saha-adbd.service
```

The gadget setup refuses an existing gadget or FunctionFS mount. Stop the
owning service before changing its files. FunctionFS endpoints are filesystem
entries, **not character devices**: test them with `test -e`, not `test -c`.
The activation step waits for ep1/ep2 before binding the UDC, because systemd
readiness notification can arrive before the USB worker publishes endpoints.

## Rollback

Run through the serial console (stopping ADB closes any ADB shell):

```sh
sudo systemctl disable --now saha-adbd.service
```

This unbinds and removes only the gadget created by this service. To uninstall
afterwards, remove the two installed files
`/etc/systemd/system/saha-adbd.service` and
`/usr/local/sbin/saha-adb-gadget`, and the isolated `/opt/saha-adbd` directory,
then run `sudo systemctl daemon-reload`. Retain the bundle for recovery.

## Upstream references

- [Debian Linux adbd setup](https://sources.debian.org/src/android-platform-tools/34.0.5-12/debian/README.adbd/)
- [Debian daemon transport selection](https://sources.debian.org/src/android-platform-tools/34.0.5-12/packages/modules/adb/daemon/main.cpp/)
- [Qualcomm PSCI vendor reset proposal](https://patches.linaro.org/project/linux-pm/patch/20250303-arm-psci-system_reset2-vendor-reboots-v9-2-b2cf4a20feda%40oss.qualcomm.com/)
- [Qualcomm flash package and EDL workflow](https://github.com/qualcomm-linux/meta-qcom/blob/master/docs/flashing.md)
