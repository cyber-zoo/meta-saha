DESCRIPTION = "Network management for Saha RDK X5 images"
LICENSE = "MIT"

inherit packagegroup

# NetworkManager owns Wi-Fi only. systemd-networkd remains authoritative for
# onboard Ethernet, USB host adapters, and the USB gadget interfaces. The
# shared packagegroup supplies NetworkManager, nmcli, Wi-Fi and wpa-supplicant.
RDEPENDS:${PN} = " \
    packagegroup-saha-network \
    saha-rdk-x5-network \
    systemd-networkd \
"
