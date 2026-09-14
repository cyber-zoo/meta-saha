DESCRIPTION = "Saha robot image for Qualcomm Dragonwing IQ-9075 EVK"
LICENSE = "MIT"

require recipes-saha/images/saha-image-common.inc

CORE_IMAGE_BASE_INSTALL += "packagegroup-saha-ros2"

# These modules supply the EVK's Ethernet MAC address and Wi-Fi slot power;
# without them the already packaged network drivers remain probe-deferred.
CORE_IMAGE_BASE_INSTALL += "kernel-module-at24 kernel-module-pwrseq-pcie-m2"
CORE_IMAGE_BASE_INSTALL += "saha-usb-adb"
