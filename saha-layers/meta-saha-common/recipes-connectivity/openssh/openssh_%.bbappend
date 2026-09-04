FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

SRC_URI += "file://99-saha-root-empty-password.conf"

do_install:append() {
    install -d ${D}${sysconfdir}/ssh/sshd_config.d
    install -m 0644 ${UNPACKDIR}/99-saha-root-empty-password.conf \
        ${D}${sysconfdir}/ssh/sshd_config.d/
}

FILES:${PN}-sshd:append = " ${sysconfdir}/ssh/sshd_config.d/99-saha-root-empty-password.conf"
