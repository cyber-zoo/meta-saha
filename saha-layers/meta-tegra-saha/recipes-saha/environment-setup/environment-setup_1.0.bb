DESCRIPTION = "Script to set up environment variabals and paths"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta-tegra-saha/LICENSE;md5=aacb477e247a2fdef1f3aabdf98178da"

SRC_URI = "\
    file://ros_setup.sh \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}/etc/profile.d/
    install -m 0644 ${S}/ros_setup.sh ${D}/etc/profile.d/
}
