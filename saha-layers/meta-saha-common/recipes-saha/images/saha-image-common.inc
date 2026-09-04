LICENSE = "MIT"

inherit core-image

IMAGE_FEATURES += "ssh-server-openssh"
CORE_IMAGE_BASE_INSTALL += "packagegroup-saha-base"
CORE_IMAGE_BASE_INSTALL += "packagegroup-saha-network"
CORE_IMAGE_BASE_INSTALL += "${@'packagegroup-saha-systemd' if d.getVar('VIRTUAL-RUNTIME_init_manager') == 'systemd' else ''}"

inherit nopackages
