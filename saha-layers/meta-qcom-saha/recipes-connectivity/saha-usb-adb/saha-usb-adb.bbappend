FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://saha-usb-adb.conf"

RDEPENDS:${PN}:append:iq-9075-evk = " kernel-module-libcomposite kernel-module-usb-f-fs"

do_install:append() {
    install -d ${D}${sysconfdir}/default
    install -m 0644 ${UNPACKDIR}/saha-usb-adb.conf ${D}${sysconfdir}/default/saha-usb-adb
}
