SECTION = "kernel"
SUMMARY = "Linux for Rolling Tegra mini kernel recipe"
DESCRIPTION = "Linux kernel for Rolling project"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

inherit l4t_bsp
require recipes-kernel/linux/linux-yocto.inc

KERNEL_INTERNAL_WIRELESS_REGDB ?= "${@bb.utils.contains('DISTRO_FEATURES', 'wifi', '1', '0', d)}"
KERNEL_DISABLE_FW_USER_HELPER ?= "y"

DEPENDS:remove = "kern-tools-native"
DEPENDS:append = " kern-tools-tegra-native"
DEPENDS:append = "${@' wireless-regdb-native' if bb.utils.to_boolean(d.getVar('KERNEL_INTERNAL_WIRELESS_REGDB')) else ''}"

LINUX_VERSION ?= "5.10.65"
PV = "${LINUX_VERSION}+git${SRCPV}"
FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}-${@bb.parse.vars_from_file(d.getVar('FILE', False),d)[1]}:"

LINUX_VERSION_EXTENSION ?= "-l4t-r${@'.'.join(d.getVar('L4T_VERSION').split('.')[:2])}"
SCMVERSION ??= "y"

SRCBRANCH = "oe4t-patches${LINUX_VERSION_EXTENSION}-dp"
SRCREV = "4fc0249f4dd4b0e9ee905eb7d09d4d5c591fd038"
KBRANCH = "${SRCBRANCH}"
SRC_REPO = "github.com/OE4T/linux-tegra-5.10.git;protocol=https"
KERNEL_REPO = "${SRC_REPO}"
SRC_URI = "git://${KERNEL_REPO};name=machine;branch=${KBRANCH} \
           ${@'file://localversion_auto.cfg' if d.getVar('SCMVERSION') == 'y' else ''} \
           ${@'file://disable-fw-user-helper.cfg' if d.getVar('KERNEL_DISABLE_FW_USER_HELPER') == 'y' else ''} \
           ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'file://systemd.cfg', '', d)} \
           ${@'file://wireless_regdb.cfg' if d.getVar('KERNEL_INTERNAL_WIRELESS_REGDB') == '1' else ''} \
           ${@'file://mini-board-a310.patch' if d.getVar('BOARD_TYPE') == 'Rolling_A310' else ''} \
"

PATH:prepend = "${STAGING_BINDIR_NATIVE}/kern-tools-tegra:"

KBUILD_DEFCONFIG = "tegra_defconfig"
KCONFIG_MODE = "--alldefconfig"
