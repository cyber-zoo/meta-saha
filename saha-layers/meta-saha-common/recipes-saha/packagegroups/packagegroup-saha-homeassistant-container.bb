DESCRIPTION = "Docker runtime and Home Assistant container launcher"

LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = " \
    ca-certificates \
    docker \
    saha-homeassistant-container \
    saha-homeassistant-container-image \
"
