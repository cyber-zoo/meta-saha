DESCRIPTION = "Packagegroup for peripherals"

LICENSE = "Apache-2.0"

inherit packagegroup

RDEPENDS:${PN} = " \
    librealsense2 \
    librealsense2-tools \
"
