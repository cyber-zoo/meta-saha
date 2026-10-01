DESCRIPTION = "Saha ROS-free Microduck image"
LICENSE = "MIT"
require recipes-saha/images/saha-image-common.inc

CORE_IMAGE_BASE_INSTALL += "packagegroup-saha-microduck"
IMAGE_ROOTFS_EXTRA_SPACE = "262144"
IMAGE_FSTYPES += "tar.zst"
