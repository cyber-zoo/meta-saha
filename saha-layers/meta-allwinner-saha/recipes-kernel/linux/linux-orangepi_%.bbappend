FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:orangepi-zero3w = " file://microduck.cfg file://sun60i-a733-orangepi-zero3w-microduck.dts"

saha_install_microduck_dts() {
    install -m 0644 ${UNPACKDIR}/sun60i-a733-orangepi-zero3w-microduck.dts ${S}/arch/arm64/boot/dts/allwinner/
}
do_patch[postfuncs] += "saha_install_microduck_dts"

do_configure:append:orangepi-zero3w() {
    ${S}/scripts/kconfig/merge_config.sh -m -O ${B} ${B}/.config ${UNPACKDIR}/microduck.cfg
    ${KERNEL_CONFIG_COMMAND}
}
