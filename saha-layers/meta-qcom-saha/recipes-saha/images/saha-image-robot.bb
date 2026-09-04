DESCRIPTION = "Saha robot image for Qualcomm Dragonwing IQ-9075 EVK"
LICENSE = "MIT"

require recipes-saha/images/saha-image-common.inc

CORE_IMAGE_BASE_INSTALL += "packagegroup-saha-ros2"
