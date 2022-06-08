DESCRIPTION = "Saha base image for tegra"

require saha-image-common.inc

IMAGE_FEATURES += "hwcodecs"

CORE_IMAGE_BASE_INSTALL += "nvidia-docker cuda-libraries"
CORE_IMAGE_BASE_INSTALL += "packagegroup-saha-ros"
CORE_IMAGE_BASE_INSTALL += "packagegroup-saha-peripheral"
