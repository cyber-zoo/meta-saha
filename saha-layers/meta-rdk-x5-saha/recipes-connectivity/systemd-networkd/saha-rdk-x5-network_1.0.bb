SUMMARY = "Managed wired DHCP profile for Saha RDK X5 images"
DESCRIPTION = "Installs the deterministic RDK X5 Ethernet DHCP profile used by systemd-networkd."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

COMPATIBLE_MACHINE = "^rdk-x5$"
PACKAGE_ARCH = "${MACHINE_ARCH}"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI = "file://20-saha-eth0.network"
S = "${UNPACKDIR}"

RDEPENDS:${PN} = "systemd-networkd"

do_install() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${UNPACKDIR}/20-saha-eth0.network \
        ${D}${sysconfdir}/systemd/network/20-saha-eth0.network
}

FILES:${PN} = "${sysconfdir}/systemd/network/20-saha-eth0.network"
CONFFILES:${PN} = "${sysconfdir}/systemd/network/20-saha-eth0.network"
