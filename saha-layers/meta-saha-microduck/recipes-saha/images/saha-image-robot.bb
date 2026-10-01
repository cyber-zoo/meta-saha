DESCRIPTION = "Saha ROS-free Microduck image"
LICENSE = "MIT"
require recipes-saha/images/saha-image-common.inc

# Runtime packages are introduced as a separately checked increment.
IMAGE_ROOTFS_EXTRA_SPACE = "262144"
