DESCRIPTION = "Packagegroup for peripherals"

LICENSE = "Apache-2.0"

inherit packagegroup

RDEPENDS:${PN} = " \
    l4t-usb-device-mode \
"
