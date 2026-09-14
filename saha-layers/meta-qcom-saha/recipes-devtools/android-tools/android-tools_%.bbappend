# The shared Saha service owns ConfigFS and UDC selection. Do not install
# upstream's legacy gadget policy or enable a second daemon on this BSP.
RDEPENDS:${PN}-adbd:remove = "${PN}-conf"
SYSTEMD_AUTO_ENABLE:${PN}-adbd = "disable"
