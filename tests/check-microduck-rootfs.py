#!/usr/bin/env python3
"""Inspect an extracted Saha Microduck image without executing target code."""
import argparse
from collections import deque
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import struct
import subprocess
import tomllib


def image_path(root, path):
    """Resolve image symlinks with chroot semantics, never host semantics."""
    pending = deque(PurePosixPath(path).parts)
    resolved = []
    links = 0
    while pending:
        part = pending.popleft()
        if part in ("/", "."):
            continue
        if part == "..":
            if resolved:
                resolved.pop()
            continue
        candidate = root.joinpath(*resolved, part)
        if candidate.is_symlink():
            links += 1
            if links > 40:
                raise ValueError(f"image symlink loop: {path}")
            target = os.readlink(candidate)
            if target.startswith("/"):
                resolved.clear()
            pending.extendleft(reversed(PurePosixPath(target).parts))
        else:
            resolved.append(part)
    return root.joinpath(*resolved)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def inspect(root, manifest, machine, metadata):
    def path(name):
        return image_path(root, name)

    def read(name):
        return path(name).read_text()

    packages = {line.split()[0] for line in manifest.read_text().splitlines() if line.strip()}
    required = {"microduck-runtime", "microduck-policies", "onnxruntime-bin",
                "microduck-gst-webrtc", "microduck-audio", "microduck-bluetooth-uart",
                "networkmanager", "bluez5"}
    board = "radxa" if machine == "radxa-zero-3w" else "orangepi"
    required.add(f"saha-{board}-microduck")
    required.update({"radxa-aic8800-firmware", "radxa-ap6256-firmware"}
                    if board == "radxa" else {"allwinner-aic8800-firmware"})
    require(required <= packages, f"missing packages: {sorted(required - packages)}")
    forbidden = re.compile(r"^(?:ros(?:2)?(?:-|$)|ament-|rcl(?:cpp|py)?(?:-|$)|rmw-|"
                           r"rosidl-|colcon-|docker(?:-|$)|homeassistant|packagegroup-saha-ros2)")
    require(not any(forbidden.match(name) for name in packages), "ROS/container package in image")
    require(not path("/opt/ros").exists() and not path("/usr/bin/ros2").exists(), "ROS files in image")

    runtime_recipe = metadata / "saha-layers/meta-saha-microduck/recipes-robot/microduck/microduck-runtime_0.15.0.bb"
    expected_revision = re.search(r'MICRODUCK_SRCREV = "([0-9a-f]{40})"', runtime_recipe.read_text()).group(1)
    version = tomllib.loads(read("/opt/robot/daemon/current/version.toml"))
    require(version["version"] == "0.15.0" and version["revision"] == expected_revision,
            "runtime release/source mismatch")
    require(os.readlink(root / "opt/robot/daemon/current") == "releases/0.15.0", "daemon release link")
    require(os.readlink(root / "opt/robot/policies/current") == "releases/seed-v5", "policy release link")
    require(path("/usr/bin/robotctl") == path("/opt/robot/daemon/current/bin/robotctl"), "robotctl link")

    libraries = {}
    for directory, _, files in os.walk(path("/usr/lib")):
        for name in files:
            if ".so" in name:
                libraries.setdefault(name, Path(directory) / name)
    elf_paths = [f"/opt/robot/daemon/current/bin/{name}" for name in version["binaries"]]
    elf_paths += ["/usr/lib/libonnxruntime.so.1", "/usr/lib/libonnxruntime_providers_shared.so",
                  "/usr/lib/gstreamer-1.0/libgstrswebrtc.so", "/usr/lib/gstreamer-1.0/libgstrsrtp.so"]
    dependencies = {}
    for name in elf_paths:
        binary = path(name)
        with binary.open("rb") as stream:
            header = stream.read(20)
        require(len(header) == 20 and header[:6] == b"\x7fELF\x02\x01"
                and struct.unpack_from("<H", header, 18)[0] == 183,
                f"not AArch64 ELF: {name}")
        require(stat.S_IMODE(binary.stat().st_mode) & 0o111, f"not executable: {name}")
        dynamic = subprocess.check_output(["readelf", "-d", str(binary)], text=True)
        needed = re.findall(r"Shared library: \[(.*?)\]", dynamic)
        for library in needed:
            require(library in libraries and path(libraries[library].relative_to(root)).is_file(),
                    f"{name}: missing {library}")
        dependencies[name] = needed
    require(path("/lib/ld-linux-aarch64.so.1").is_file(), "AArch64 dynamic loader missing")

    recipe = metadata / "saha-layers/meta-saha-microduck/recipes-robot/microduck-policies/microduck-policies_5.bb"
    hashes = dict(re.findall(r'SRC_URI\[(\w+)\.sha256sum\] = "([0-9a-f]{64})"', recipe.read_text()))
    require(len(hashes) == 11, "expected ten policies and their manifest")
    for name, expected in hashes.items():
        suffix = ".json" if name == "manifest" else ".onnx"
        model = path(f"/opt/robot/policies/current/{name}{suffix}")
        require(hashlib.sha256(model.read_bytes()).hexdigest() == expected, f"policy checksum: {name}")

    params = tomllib.loads(read("/etc/robot/robotd.toml"))
    require(params["bus"]["port"] == "/dev/serial0" and not params["bus"]["fast_sync_read"], "bus defaults")
    require(params["control"]["hz"] == 50 and not params["policy"]["enabled"], "commissioning defaults")
    require(not params["policy"]["voltage_adapt"] and params["policy"]["nominal_voltage"] == 5.0, "5 V HAT defaults")
    require(not params["safety"]["battery_empty_shutdown"], "incorrect 2S shutdown on 5 V rail")
    require(params["media"]["source"] == "test", "unqualified camera selected")
    require("battery" not in params and "body_imu" not in params, "obsolete runtime config tables")
    updater = tomllib.loads(read("/etc/robot/updater.toml"))
    require(updater["auto_apply"] == "off" and "check_interval" not in updater,
            "scheduled Debian OTA enabled")
    require(updater["component"]["daemon"]["source"]["tag_prefix"] == "saha-daemon-v",
            "unqualified Debian feed selected")

    passwd = {line.split(":")[0] for line in read("/etc/passwd").splitlines()}
    groups = {line.split(":")[0] for line in read("/etc/group").splitlines()}
    require({"root", "btd", "padd", "mediad", "tofd"} <= passwd, "service accounts missing")
    require({"robot", "i2c", "input", "video", "render", "bluetooth"} <= groups, "device/IPC groups missing")
    enabled = ("robotd", "configd", "btd", "padd", "mediad", "updaterd",
               "microduck-audio-init", "microduck-bluetooth-uart")
    for unit in enabled:
        link = f"/etc/systemd/system/multi-user.target.wants/{unit}.service"
        require(path(link).is_file(), f"unit not enabled: {unit}")
    for unit in ("robotd", "configd", "btd", "padd", "mediad", "updaterd", "tofd"):
        require(path(f"/usr/lib/systemd/system/{unit}.service").is_file(), f"unit missing: {unit}")
        dropin = read(f"/usr/lib/systemd/system/{unit}.service.d/10-yocto.conf")
        require("Environment=ORT_DYLIB_PATH=/usr/lib/libonnxruntime.so.1" in dropin, f"ORT environment: {unit}")
        require("Environment=GST_PLUGIN_PATH=/usr/lib/gstreamer-1.0" in dropin, f"GST environment: {unit}")
    require(not path("/etc/systemd/system/multi-user.target.wants/tofd.service").exists(), "optional ToF enabled")
    require('GROUP="i2c", MODE="0660"' in read(f"/etc/udev/rules.d/60-microduck-{board}.rules"), "I2C permissions")
    rules = read(f"/etc/udev/rules.d/60-microduck-{board}.rules")
    require(f'KERNEL=="ttyS{2 if board == "radxa" else 0}"' in rules and 'SYMLINK+="serial0"' in rules,
            "motor UART alias")
    require(path("/usr/bin/hciattach").is_file(), "Bluetooth UART tool missing")
    modules = path("/usr/lib/modules")
    require(any(modules.rglob("hci_uart.ko*")), "HCI UART module missing")
    require(any(modules.rglob("aic8800_fdrv.ko*")), "AIC SDIO module missing")
    gst_recipe = metadata / "saha-layers/meta-saha-microduck/recipes-multimedia/gstreamer/microduck-gst-webrtc_3.bb"
    gst_revision = re.search(r'MICRODUCK_GST_SRCREV = "([0-9a-f]{40})"', gst_recipe.read_text()).group(1)
    require(path("/usr/share/saha/microduck/gst-source/source-revision").read_text().strip()
            == gst_revision, "GST source provenance")

    return {"machine": machine, "runtime": version["version"], "revision": expected_revision,
            "packages": len(packages), "policy_models": len(hashes) - 1,
            "enabled_units": list(enabled), "elf_dependencies": dependencies,
            "scope": "rootfs inspection; no target execution or hardware proof"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rootfs", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--machine", choices=("radxa-zero-3w", "orangepi-zero3w"), required=True)
    parser.add_argument("--metadata", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    try:
        report = inspect(args.rootfs.resolve(strict=True), args.manifest, args.machine, args.metadata)
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"FAIL: {error}\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
