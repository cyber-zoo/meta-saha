DESCRIPTION = "Saha base image for tegra"

require recipes-saha/images/saha-image-common.inc

IMAGE_FEATURES += "hwcodecs"

CORE_IMAGE_BASE_INSTALL += "cuda-libraries"
CORE_IMAGE_BASE_INSTALL += "packagegroup-saha-tegra"
CORE_IMAGE_BASE_INSTALL += "packagegroup-saha-peripheral"

TOOLCHAIN_HOST_TASK += "nativesdk-packagegroup-cuda-sdk-host"
