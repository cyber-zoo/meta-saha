SUMMARY = "Explicit PREEMPT_RT status and latency measurement runner"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
SRC_URI = "file://saha-rt-tests"
S = "${UNPACKDIR}"
COMPATIBLE_MACHINE = "^rdk-x5$"
RDEPENDS:${PN} = "python3-core python3-compression python3-json python3-io python3-shell rt-tests stress-ng coreutils util-linux-dmesg"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/saha-rt-tests ${D}${bindir}/
}
