SUMMARY = "Microduck AIC/Broadcom radio UART initialization"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
SRC_URI = "file://microduck-bluetooth-uart file://microduck-bluetooth-uart.service"
S = "${UNPACKDIR}"
inherit allarch systemd
RDEPENDS:${PN} = "bluez5"
SYSTEMD_SERVICE:${PN} = "microduck-bluetooth-uart.service"

do_install() {
    install -d ${D}${libexecdir}/microduck ${D}${systemd_system_unitdir}
    install -m 0755 ${UNPACKDIR}/microduck-bluetooth-uart ${D}${libexecdir}/microduck/
    sed 's|@LIBEXECDIR@|${libexecdir}|g' ${UNPACKDIR}/microduck-bluetooth-uart.service > ${D}${systemd_system_unitdir}/microduck-bluetooth-uart.service
}
FILES:${PN} += "${libexecdir}/microduck ${systemd_system_unitdir}"
