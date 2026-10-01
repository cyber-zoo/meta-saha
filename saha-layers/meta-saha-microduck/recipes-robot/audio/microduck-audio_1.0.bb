SUMMARY = "Microduck HAT AIC3104 mixer initialization"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
SRC_URI = "file://microduck-audio-init file://microduck-audio-init.service"
S = "${UNPACKDIR}"
inherit allarch systemd
RDEPENDS:${PN} = "alsa-utils-amixer"
SYSTEMD_SERVICE:${PN} = "microduck-audio-init.service"

do_install() {
    install -d ${D}${libexecdir}/microduck ${D}${systemd_system_unitdir}
    install -m 0755 ${UNPACKDIR}/microduck-audio-init ${D}${libexecdir}/microduck/
    sed 's|@LIBEXECDIR@|${libexecdir}|g' ${UNPACKDIR}/microduck-audio-init.service > ${D}${systemd_system_unitdir}/microduck-audio-init.service
}
FILES:${PN} += "${libexecdir}/microduck ${systemd_system_unitdir}"
