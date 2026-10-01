DESCRIPTION = "ROS 2 runtime packagegroup for Saha robot images"

LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = " \
    ros-base \
    ros2cli-common-extensions \
"
