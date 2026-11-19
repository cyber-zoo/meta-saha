FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit saha-rdk-x5-preempt-rt

SAHA_X5_KERNEL_RT_ENABLED = "${@'1' if d.getVar('SAHA_X5_PREEMPT_RT') == '1' and d.getVar('MACHINE') == 'rdk-x5' else '0'}"
SAHA_X5_RT_FILES = " \
    file://0001-rdk-x5-preempt-rt-6.1.83-rt28.patch \
    file://0002-rdk-x5-pps-use-IRQ-core-RT-scheduling.patch \
    file://0003-rdk-x5-pps-client-avoid-null-IRQ-action.patch \
    file://0004-cacheinfo-fix-cache-node-refcount.patch \
    file://0005-cacheinfo-retain-firmware-token.patch \
    file://0006-cacheinfo-generic-OF-cache-levels.patch \
    file://0007-cacheinfo-return-OF-errors.patch \
    file://0008-cacheinfo-count-split-cache-leaves.patch \
    file://0009-arch-topology-preallocate-cacheinfo.patch \
    file://0010-acpi-pptt-remove-old-cache-level-helper.patch \
    file://0011-acpi-pptt-provide-cache-info-api.patch \
    file://0012-rdk-x5-crypto-keep-IRQs-enabled-in-ACA-PM.patch \
    file://0013-rdk-x5-coresight-use-raw-locks-for-atomic-callbacks.patch \
    file://saha-rdk-x5-preempt-rt.cfg \
"
SRC_URI:append = "${@d.getVar('SAHA_X5_RT_FILES') if d.getVar('SAHA_X5_KERNEL_RT_ENABLED') == '1' else ''}"

python () {
    if d.getVar('SAHA_X5_KERNEL_RT_ENABLED') == '1':
        if d.getVar('SRCREV_kernel') != 'c642eabfd7aacc4f44f2300e69d27ef1691a47d7':
            bb.fatal('X5 RT patch is qualified only against the pinned RDKOS 3.5.0 kernel commit')
}

do_configure:append() {
    if [ "${SAHA_X5_KERNEL_RT_ENABLED}" = "1" ]; then
        # This vendor recipe inherits kernel, not kernel-yocto: merge its
        # fragment explicitly after the vendor defconfig/olddefconfig pass.
        ${S}/scripts/kconfig/merge_config.sh -m -O ${B} ${B}/.config ${UNPACKDIR}/saha-rdk-x5-preempt-rt.cfg
        oe_runmake -C ${S} O=${B} olddefconfig
    fi
}
