DESCRIPTION = "ROS 2 Jazzy runtime packagegroup for Saha RDK X5 robot images"
LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = " \
    ros-base \
    ros2cli-common-extensions \
"
