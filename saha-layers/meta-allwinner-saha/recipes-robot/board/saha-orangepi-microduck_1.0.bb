SUMMARY = "Orange Pi Microduck motor and HAT device aliases"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
SRC_URI = "file://60-microduck-orangepi.rules file://microduck-modules.conf"
S = "${UNPACKDIR}"
COMPATIBLE_MACHINE = "^orangepi-zero3w$"
PACKAGE_ARCH = "${MACHINE_ARCH}"
RDEPENDS:${PN} = "microduck-bluetooth-uart"

do_install() {
    install -d ${D}${sysconfdir}/udev/rules.d ${D}${sysconfdir}/modules-load.d
    install -m 0644 ${UNPACKDIR}/60-microduck-orangepi.rules ${D}${sysconfdir}/udev/rules.d/
    install -m 0644 ${UNPACKDIR}/microduck-modules.conf ${D}${sysconfdir}/modules-load.d/
}
