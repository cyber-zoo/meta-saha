DESCRIPTION = "Systemd tools packagegroup for Saha RDK X5 images"
LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = " \
    less \
    systemd-analyze \
"
