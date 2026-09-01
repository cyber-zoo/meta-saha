FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://10-rdk-x5-wifi.conf \
    file://99-saha-rdk-x5-unmanaged-devices.conf \
"

# Keep the required plugins explicit so an upstream PACKAGECONFIG default
# change cannot silently leave the split nmcli or Wi-Fi packages empty.
PACKAGECONFIG:append = " nmcli wifi"

inherit features_check

REQUIRED_DISTRO_FEATURES:append = " systemd wifi"

SYSTEMD_AUTO_ENABLE:${PN}-daemon = "enable"

do_install:append() {
    install -d ${D}${sysconfdir}/NetworkManager/conf.d
    install -m 0644 ${UNPACKDIR}/99-saha-rdk-x5-unmanaged-devices.conf \
        ${D}${sysconfdir}/NetworkManager/conf.d/

    install -d ${D}${systemd_system_unitdir}/NetworkManager.service.d
    install -m 0644 ${UNPACKDIR}/10-rdk-x5-wifi.conf \
        ${D}${systemd_system_unitdir}/NetworkManager.service.d/
}

FILES:${PN}-daemon += " \
    ${sysconfdir}/NetworkManager/conf.d/99-saha-rdk-x5-unmanaged-devices.conf \
    ${systemd_system_unitdir}/NetworkManager.service.d/10-rdk-x5-wifi.conf \
"
