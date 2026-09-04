DESCRIPTION = "Jetson-specific packagegroup for Saha images"

LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = " \
    tegra-tools-tegrastats \
"
