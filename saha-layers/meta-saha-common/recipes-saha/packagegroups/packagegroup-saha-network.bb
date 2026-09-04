DESCRIPTION = "NetworkManager and WiFi tools for Saha images"

LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = " \
    networkmanager \
    networkmanager-daemon \
    networkmanager-nmcli \
    networkmanager-wifi \
    wpa-supplicant \
"
