IMAGE_FEATURES += "ssh-server-openssh"

LICENSE = "MIT"

inherit core-image

CORE_IMAGE_BASE_INSTALL += "packagegroup-saha-base"
CORE_IMAGE_BASE_INSTALL += "${@bb.utils.contains('DISTRO_FEATURES', 'buildtest', 'packagegroup-saha-basetests', '', d)}"
CORE_IMAGE_BASE_INSTALL += "${@'packagegroup-saha-systemd' if d.getVar('VIRTUAL-RUNTIME_init_manager') == 'systemd' else ''}"

inherit nopackages
