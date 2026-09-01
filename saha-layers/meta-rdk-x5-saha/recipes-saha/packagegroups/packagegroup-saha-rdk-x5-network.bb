DESCRIPTION = "Network management for Saha RDK X5 images"
LICENSE = "MIT"

inherit packagegroup

# NetworkManager owns Wi-Fi only. systemd-networkd remains authoritative for
# onboard Ethernet, USB host adapters, and the USB gadget interfaces.
RDEPENDS:${PN} = " \
    networkmanager-daemon \
    networkmanager-nmcli \
    networkmanager-wifi \
    saha-rdk-x5-network \
    systemd-networkd \
    wpa-supplicant \
"
