DESCRIPTION = "Base packagegroup for Saha RDK X5 images"
LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = " \
    packagegroup-saha-base \
    packagegroup-saha-rdk-x5-network \
"
