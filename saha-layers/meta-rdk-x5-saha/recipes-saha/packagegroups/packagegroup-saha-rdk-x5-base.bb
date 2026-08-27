DESCRIPTION = "Base packagegroup for Saha RDK X5 images"
LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = " \
    haveged \
    procps \
    sshfs-fuse \
    strace \
    can-utils \
    dosfstools \
    systemd-networkd \
    saha-rdk-x5-network \
"
