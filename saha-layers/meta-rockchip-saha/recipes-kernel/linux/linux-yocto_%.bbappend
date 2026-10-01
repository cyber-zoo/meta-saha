FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:radxa-zero-3w = " file://microduck.cfg file://rk3566-radxa-zero-3w-microduck.dts"

do_patch:append:radxa-zero-3w() {
    install -m 0644 ${UNPACKDIR}/rk3566-radxa-zero-3w-microduck.dts ${S}/arch/arm64/boot/dts/rockchip/
}
