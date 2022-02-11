DESCRIPTION = "Packagegroup for ROS"

LICENSE = "Apache-2.0"

inherit packagegroup

RDEPENDS:${PN} = " \
    ros-base \
    environment-setup \
"
