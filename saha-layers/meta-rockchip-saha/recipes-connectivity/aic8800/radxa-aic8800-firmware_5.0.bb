SUMMARY = "Pinned AIC8800D80 SDIO firmware for the Radxa module ABI"
LICENSE = "CLOSED"
LICENSE_FLAGS = "radxa-radio-firmware"
require aic8800-source.inc
PACKAGE_ARCH = "${MACHINE_ARCH}"
INHIBIT_DEFAULT_DEPS = "1"
# The repository's root Makefile builds unrelated diagnostic executables.
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${nonarch_base_libdir}/firmware/aic8800_fw/SDIO/aic8800D80
    install -m 0644 ${S}/src/SDIO/driver_fw/fw/aic8800D80/* ${D}${nonarch_base_libdir}/firmware/aic8800_fw/SDIO/aic8800D80/
}
FILES:${PN} = "${nonarch_base_libdir}/firmware"
