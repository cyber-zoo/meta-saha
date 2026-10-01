SUMMARY = "Pinned Radxa AP6256 Wi-Fi and Bluetooth firmware"
HOMEPAGE = "https://github.com/radxa/rkwifibt"
LICENSE = "CLOSED"
LICENSE_FLAGS = "radxa-radio-firmware"
COMPATIBLE_MACHINE = "^radxa-zero-3w$"
PACKAGE_ARCH = "${MACHINE_ARCH}"
INHIBIT_DEFAULT_DEPS = "1"

RADXA_RKWIFIBT_SRCREV = "b61a1e8499a4f1956ef417cbcfaa6c2cf805ce08"
FW_BASE = "https://raw.githubusercontent.com/radxa/rkwifibt/${RADXA_RKWIFIBT_SRCREV}/firmware/broadcom/AP6256"
SRC_URI = " \
    ${FW_BASE}/wifi/fw_bcm43456c5_ag.bin;name=wifi;downloadfilename=radxa-ap6256-fw_bcm43456c5_ag.bin \
    ${FW_BASE}/wifi/nvram_ap6256.txt;name=nvram;downloadfilename=radxa-ap6256-nvram_ap6256.txt \
    ${FW_BASE}/bt/BCM4345C5.hcd;name=bt;downloadfilename=radxa-ap6256-BCM4345C5.hcd \
"
SRC_URI[wifi.sha256sum] = "537f0a552e27034d0ef2c7609cb0d851d73d49cced2ff6997f7d0f2353598da5"
SRC_URI[nvram.sha256sum] = "588430b4c2c167ca035f17da7478bec3d4922487152610d385d5ccb8f7c0a75f"
SRC_URI[bt.sha256sum] = "37d259a4198e8aa073e94258465ba993554316353b8f049e6f6f72ec3ae87da4"

do_install() {
    install -d ${D}${nonarch_base_libdir}/firmware/brcm
    install -m 0644 ${UNPACKDIR}/radxa-ap6256-fw_bcm43456c5_ag.bin ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43456-sdio.bin
    install -m 0644 ${UNPACKDIR}/radxa-ap6256-nvram_ap6256.txt ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43456-sdio.txt
    install -m 0644 ${UNPACKDIR}/radxa-ap6256-BCM4345C5.hcd ${D}${nonarch_base_libdir}/firmware/brcm/BCM4345C5.hcd
}
FILES:${PN} = "${nonarch_base_libdir}/firmware/brcm"
