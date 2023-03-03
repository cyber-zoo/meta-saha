DESCRIPTION = "Tegra saha flash layout files"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

INHIBIT_DEFAULT_DEPS = "1"
COMPATIBLE_MACHINE = "(apollo)"

SRC_URI = "file://flash_${MACHINE}.xml \
           file://flash_qspi_${MACHINE}.xml"
PARTITION_LAYOUT_DIR = "tegra-saha-layout"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${datadir}/${PARTITION_LAYOUT_DIR}
    install -m 0644 ${S}/flash_qspi_${MACHINE}.xml ${D}${datadir}/${PARTITION_LAYOUT_DIR}/
    install -m 0644 ${S}/flash_${MACHINE}.xml ${D}${datadir}/${PARTITION_LAYOUT_DIR}/
}

PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit nopackages
