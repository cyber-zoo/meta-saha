FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# This pinned BSP's EVK DT still uses the pre-reboot-mode cookie/type order.
SRC_URI:append:iq-9075-evk = " file://0001-arm64-dts-qcom-lemans-evk-fix-PSCI-reset-arguments.patch"
