# qcomflash grows the GPT rootfs partition to fill UFS, but ext4 retains the
# build-time image size unless systemd grows it during first boot.
do_install:append:iq-9075-evk() {
    sed -i '\|^/dev/root[[:space:]]|s/defaults/defaults,x-systemd.growfs/' ${D}${sysconfdir}/fstab
}
