SUMMARY = "Official Home Assistant container launcher for Saha images"
DESCRIPTION = "Installs a systemd-managed wrapper that runs the official \
Home Assistant container image with host networking."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://saha-homeassistant-container.sh \
    file://saha-homeassistant-container.env \
    file://homeassistant-container.service \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = "homeassistant-container.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

RDEPENDS:${PN} = "bash docker"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/saha-homeassistant-container.sh ${D}${bindir}/saha-homeassistant-container

    install -d ${D}${sysconfdir}/default
    install -m 0644 ${UNPACKDIR}/saha-homeassistant-container.env ${D}${sysconfdir}/default/homeassistant-container

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/homeassistant-container.service ${D}${systemd_system_unitdir}

    install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf ${systemd_system_unitdir}/homeassistant-container.service \
        ${D}${sysconfdir}/systemd/system/multi-user.target.wants/homeassistant-container.service
}

FILES:${PN} += " \
    ${sysconfdir}/default/homeassistant-container \
    ${sysconfdir}/systemd/system/multi-user.target.wants/homeassistant-container.service \
"
