SUMMARY = "Saha USB-only development ADB service"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://saha-adb-gadget file://saha-usb-adb.service"
S = "${UNPACKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "saha-usb-adb.service"
RDEPENDS:${PN} = "android-tools-adbd kmod util-linux-mountpoint"

do_install() {
    install -d ${D}${sbindir} ${D}${systemd_system_unitdir}
    install -m 0755 ${S}/saha-adb-gadget ${D}${sbindir}/saha-adb-gadget
    install -m 0644 ${S}/saha-usb-adb.service ${D}${systemd_system_unitdir}/saha-usb-adb.service
}
