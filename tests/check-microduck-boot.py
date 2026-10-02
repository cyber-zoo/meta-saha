#!/usr/bin/env python3
"""Inspect board WIC boot bytes, DT and ext4 contents without mounting media."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import zlib

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("rootfs_check", Path(__file__).with_name("check-microduck-rootfs.py"))
rootfs_check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rootfs_check)
require = rootfs_check.require


def sha256(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def check_uimage(data):
    require(len(data) >= 64, "truncated uImage")
    magic, checksum, _, size, load, entry, payload_crc, os_id, arch, kind, compression, _ = struct.unpack(
        ">7I4B32s", data[:64])
    require(magic == 0x27051956, "uImage magic")
    header = bytearray(data[:64])
    header[4:8] = b"\0" * 4
    require(zlib.crc32(header) == checksum, "uImage header checksum")
    require(len(data) == size + 64 and zlib.crc32(data[64:]) == payload_crc, "uImage payload checksum/length")
    require((os_id, arch, kind, compression) == (5, 2, 2, 0), "vendor bootm needs Linux/ARM/kernel/uncompressed header")
    require(load == entry == 0x41000000, "A733 kernel load/entry address")
    return data[64:]


def check_gpt(stream, sectors):
    for lba in (1, sectors - 1):
        stream.seek(lba * 512)
        header = bytearray(stream.read(512))
        require(header[:8] == b"EFI PART", "GPT signature")
        size, checksum = struct.unpack_from("<II", header, 12)
        require(92 <= size <= 512, "GPT header size")
        header[16:20] = b"\0" * 4
        require(zlib.crc32(header[:size]) == checksum, "GPT header checksum")
        current, backup = struct.unpack_from("<QQ", header, 24)
        require(current == lba and backup == (sectors - 1 if lba == 1 else 1), "GPT header locations")
        table_lba, entries, width, table_crc = struct.unpack_from("<QIII", header, 72)
        require(width == 128 and 1 <= entries <= 128, "GPT partition array size")
        stream.seek(table_lba * 512)
        table = stream.read(entries * width)
        require(len(table) == entries * width and zlib.crc32(table) == table_crc, "GPT partition array checksum")


def fdt(path, node, prop, kind="s"):
    return subprocess.check_output(["fdtget", "-t", kind, str(path), node, prop], text=True).strip()


def inspect(wic, deploy, root, machine):
    require(wic.is_file(), "WIC must be a regular image file")
    result = subprocess.run(["sfdisk", "--json", str(wic)], text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, check=True)
    require(not result.stderr.strip(), f"partition table warning: {result.stderr}")
    table = json.loads(result.stdout)["partitiontable"]
    require(table["sectorsize"] == 512, "sector size")
    parts = table["partitions"]
    with wic.open("rb") as stream:
        mbr = stream.read(512)
        require(mbr[510:512] == b"\x55\xaa", "MBR signature")
        if machine == "radxa-zero-3w":
            require(table["label"] == "gpt", "Rockchip GPT layout")
            check_gpt(stream, wic.stat().st_size // 512)
            expected = {"loader1": 64, "v_storage": 7168, "reserved": 7680, "reserved1": 8064,
                        "uboot_env": 8128, "reserved2": 8192, "loader2": 16384, "atf": 24576,
                        "rootfsA": 32768}
            require({part["name"]: part["start"] for part in parts} == expected, "Rockchip partition offsets")
            root_part = parts[-1]
            boot = (("idbloader.img", 64 * 512, 7104 * 512), ("u-boot.itb", 16384 * 512, 8192 * 512))
        else:
            require(table["label"] == "dos" and len(parts) == 1 and parts[0]["type"] == "83",
                    "A733 single-ext4 MBR layout")
            root_part = parts[0]
            require(root_part["start"] == 65536, "A733 rootfs offset")
            boot = (("boot0-orangepi-zero3w.bin", 8 * 1024, 16400 * 1024 - 8 * 1024),
                    ("boot-package-orangepi-zero3w.bin", 16400 * 1024, (32768 - 16400) * 1024))
        previous = 0
        for part in parts:
            require(part["start"] >= previous and part["size"] > 0, "overlapping/empty partition")
            previous = part["start"] + part["size"]
        require(previous * 512 <= wic.stat().st_size, "partition exceeds image")
        boot_hashes = {}
        for name, offset, maximum in boot:
            data = (deploy / name).read_bytes()
            require(0 < len(data) <= maximum, f"boot input size: {name}")
            stream.seek(offset)
            require(stream.read(len(data)) == data, f"WIC boot input differs: {name}")
            boot_hashes[name] = hashlib.sha256(data).hexdigest()
        stream.seek(root_part["start"] * 512 + 1024 + 56)
        require(stream.read(2) == b"\x53\xef", "rootfs is not ext4")

        with tempfile.TemporaryDirectory(prefix="saha-boot-check-") as temporary:
            temp = Path(temporary)
            filesystem = temp / "root.ext4"
            stream.seek(root_part["start"] * 512)
            remaining = root_part["size"] * 512
            with filesystem.open("wb") as output:
                while remaining:
                    data = stream.read(min(remaining, 1024 * 1024))
                    require(data, "truncated rootfs partition")
                    output.write(data)
                    remaining -= len(data)
            fsck = subprocess.run(["e2fsck", "-fn", str(filesystem)], stdout=subprocess.PIPE,
                                  stderr=subprocess.STDOUT, text=True)
            require(fsck.returncode == 0, f"ext4 consistency check failed: {fsck.stdout}")
            files = ["/etc/robot/robotd.toml", "/opt/robot/daemon/current/version.toml",
                     "/opt/robot/daemon/current/bin/robotd",
                     "/usr/lib/systemd/system/updaterd.service.d/20-saha-offline.conf",
                     "/opt/robot/policies/releases/seed-v5/velstand.onnx"]
            if machine == "radxa-zero-3w":
                files += ["/boot/fitImage", "/boot/extlinux/extlinux.conf"]
            else:
                files += ["/boot/uImage", "/boot/boot.scr", "/boot/boot.cmd",
                          "/boot/sun60i-a733-orangepi-zero3w-microduck.dtb"]
            extracted = {}
            for index, name in enumerate(files):
                original = rootfs_check.image_path(root, name)
                actual_name = "/" + str(original.relative_to(root))
                output = temp / f"file-{index}"
                subprocess.run(["debugfs", "-R", f"dump {actual_name} {output}", str(filesystem)],
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
                require(output.is_file() and sha256(output) == sha256(original), f"WIC/rootfs mismatch: {name}")
                extracted[name] = output
            if machine == "radxa-zero-3w":
                image = extracted["/boot/fitImage"]
                configuration = "conf-rk3566-radxa-zero-3w-microduck.dtb"
                require(fdt(image, "/configurations", "default") == configuration, "FIT default configuration")
                require(fdt(image, f"/configurations/{configuration}", "fdt")
                        == "fdt-rk3566-radxa-zero-3w-microduck.dtb", "FIT HAT DT selection")
                dt_bytes = bytes(int(value, 16) for value in fdt(
                    image, "/images/fdt-rk3566-radxa-zero-3w-microduck.dtb", "data", "bx").split())
                dt = temp / "hat.dtb"
                dt.write_bytes(dt_bytes)
                require(sha256(dt) == sha256(deploy / "rk3566-radxa-zero-3w-microduck.dtb"), "FIT DT bytes")
                cmd = extracted["/boot/extlinux/extlinux.conf"].read_text()
                require("KERNEL /boot/fitImage" in cmd and "root=PARTLABEL=rootfsA" in cmd, "extlinux kernel/root")
                sound_prop, i2c_alias, serial_alias = "simple-audio-card,name", "i2c3", "serial2"
            else:
                payload = check_uimage(extracted["/boot/uImage"].read_bytes())
                require(hashlib.sha256(payload).hexdigest() == sha256(deploy / "Image"), "uImage AArch64 payload")
                dt = extracted["/boot/sun60i-a733-orangepi-zero3w-microduck.dtb"]
                require(sha256(dt) == sha256(deploy / "sun60i-a733-orangepi-zero3w-microduck.dtb"), "deployed DT bytes")
                require(payload[56:60] == b"ARM\x64", "uImage payload is not an AArch64 Image")
                cmd = extracted["/boot/boot.cmd"].read_text()
                require("root=PARTUUID=${rootuuid}" in cmd and "bootm ${kernel_addr_r}" in cmd
                        and "sun60i-a733-orangepi-zero3w-microduck.dtb" in cmd, "A733 kernel/root/DT boot command")
                sound_prop, i2c_alias, serial_alias = "soundcard-mach,name", "i2c0", "serial0"
            require("console=tty1" in cmd and "console=ttyS" not in cmd and "earlycon" not in cmd, "motor UART console")
            require(fdt(dt, "/sound-aic3104", sound_prop) == "aic3104", "HAT sound card")
            i2c = fdt(dt, "/aliases", i2c_alias)
            require(fdt(dt, i2c, "status") == "okay" and fdt(dt, i2c, "clock-frequency", "u") == "400000",
                    "HAT I2C configuration")
            require(fdt(dt, i2c + "/codec@18", "compatible") == "ti,tlv320aic3104", "HAT codec")
            serial = fdt(dt, "/aliases", serial_alias)
            require(fdt(dt, serial, "status") == "okay", "motor UART disabled")
            stdout = subprocess.run(["fdtget", "-t", "s", str(dt), "/chosen", "stdout-path"],
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            require(stdout.returncode != 0, "DT serial stdout still enabled")
    return {"machine": machine, "wic_sha256": sha256(wic), "layout": table["label"],
            "root_start_sector": root_part["start"], "boot_inputs": boot_hashes,
            "matched_rootfs_files": files, "scope": "read-only artifact inspection; no physical boot proof"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wic", type=Path, required=True)
    parser.add_argument("--deploy", type=Path, required=True)
    parser.add_argument("--rootfs", type=Path, required=True)
    parser.add_argument("--machine", choices=("radxa-zero-3w", "orangepi-zero3w"), required=True)
    args = parser.parse_args()
    try:
        report = inspect(args.wic, args.deploy, args.rootfs.resolve(strict=True), args.machine)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"FAIL: {error}\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
