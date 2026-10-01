SUMMARY = "Radxa AIC8800 SDIO modules with pinned upstream compatibility patches"
LICENSE = "GPL-2.0-only"
# Radxa's copyright declaration assigns src/* and its patches GPL-2.0.
LIC_FILES_CHKSUM = "file://debian/copyright;md5=ccd22839cbff32b2bbe9a6ec05d11739"
require aic8800-source.inc
inherit module

AIC_MODULE_DIR = "${S}/src/SDIO/driver_fw/driver/aic8800"

aic_apply_upstream_patches() {
    while read -r name; do
        case "$name" in ''|'#'*) continue ;; esac
        # Build only SDIO; unrelated USB/PCI patches have different encodings.
        git -C ${S} apply --allow-empty --include='src/SDIO/*' ${S}/debian/patches/$name
    done < ${S}/debian/patches/series
}
do_patch[postfuncs] += "aic_apply_upstream_patches"

do_compile() {
    unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS
    oe_runmake -C ${STAGING_KERNEL_DIR} O=${STAGING_KERNEL_BUILDDIR} \
        M=${AIC_MODULE_DIR} ARCH=${ARCH} CROSS_COMPILE=${TARGET_PREFIX} \
        CC="${KERNEL_CC}" LD="${KERNEL_LD}" AR="${KERNEL_AR}" modules
}

do_install() {
    install -d ${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra
    for name in aic8800_bsp aic8800_fdrv aic8800_btlpm; do
        install -m 0644 ${AIC_MODULE_DIR}/$name/$name.ko ${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/
    done
    install -Dm0644 ${AIC_MODULE_DIR}/Module.symvers ${D}${includedir}/${BPN}/Module.symvers
}
RDEPENDS:${PN} += "radxa-aic8800-firmware"
