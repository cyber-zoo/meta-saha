SUMMARY = "Official stable Microduck ARM64 daemons"
HOMEPAGE = "https://github.com/pollen-robotics/microduck"
LICENSE = "Apache-2.0"
MICRODUCK_SRCREV = "1fa84386f07884e27866411bc1ba166977bced95"
MICRODUCK_ARCHIVE_SHA256 = "b1a10b6c2bd99e4de42774818cf94d6d1ca5a9f875e82698d68d8d5ae287eb2c"
LIC_FILES_CHKSUM = "file://microduck-source/LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"
SRCREV_source = "${MICRODUCK_SRCREV}"
SRCREV_FORMAT = "source"

SRC_URI = " \
    https://github.com/pollen-robotics/microduck/releases/download/daemon-v${PV}/daemon-${PV}.tar.zst;name=runtime \
    git://github.com/pollen-robotics/microduck.git;protocol=https;nobranch=1;name=source;destsuffix=microduck-source \
    file://robotd.toml \
    file://updater.toml \
    file://50-microduck-btd.conf \
    file://60-microduck-i2c.rules \
    file://microduck-journal.conf \
    file://20-saha-offline.conf \
"
SRC_URI[runtime.sha256sum] = "${MICRODUCK_ARCHIVE_SHA256}"
S = "${UNPACKDIR}"

inherit bin_package systemd useradd

COMPATIBLE_HOST = "aarch64.*-linux"
PACKAGE_ARCH = "${TUNE_PKGARCH}"
DEPENDS = "glib-2.0 gstreamer1.0 gstreamer1.0-plugins-base gstreamer1.0-plugins-bad systemd"
RDEPENDS:${PN} = "onnxruntime-bin microduck-policies microduck-gst-webrtc bash bluez5 networkmanager ca-certificates alsa-lib"
# These are published upstream executables, rather than linked with OE's flags.
INSANE_SKIP:${PN} = "already-stripped"

USERADD_PACKAGES = "${PN}"
GROUPADD_PARAM:${PN} = "--system robot; --system btd; --system padd; --system mediad; --system tofd; --system i2c; --system input; --system video; --system render; --system bluetooth"
USERADD_PARAM:${PN} = " \
    --system --no-create-home --home-dir / --shell /sbin/nologin --gid btd btd; \
    --system --no-create-home --home-dir / --shell /sbin/nologin --gid padd padd; \
    --system --no-create-home --home-dir / --shell /sbin/nologin --gid mediad mediad; \
    --system --no-create-home --home-dir / --shell /sbin/nologin --gid tofd tofd \
"

SYSTEMD_SERVICE:${PN} = "robotd.service configd.service btd.service padd.service mediad.service updaterd.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install() {
    release=${D}/opt/robot/daemon/releases/${PV}
    install -d "$release" ${D}${bindir} ${D}${sysconfdir}/robot
    cp -R ${S}/bin ${S}/models ${S}/docs "$release/"
    install -m 0644 ${S}/version.toml "$release/"
    ln -s releases/${PV} ${D}/opt/robot/daemon/current
    ln -s /opt/robot/daemon/current/bin/robotctl ${D}${bindir}/robotctl
    install -m 0644 ${UNPACKDIR}/robotd.toml ${D}${sysconfdir}/robot/robotd.toml
    install -m 0644 ${UNPACKDIR}/updater.toml ${D}${sysconfdir}/robot/updater.toml
    install -d ${D}${sysconfdir}/robot/trusted_keys
    install -m 0644 ${S}/microduck-source/deploy/trusted_keys/release-*.pub ${D}${sysconfdir}/robot/trusted_keys/

    install -d ${D}${systemd_system_unitdir}
    for unit in robotd configd btd padd mediad updaterd tofd; do
        install -m 0644 ${S}/systemd/$unit.service ${D}${systemd_system_unitdir}/
        install -d ${D}${systemd_system_unitdir}/$unit.service.d
        cat > ${D}${systemd_system_unitdir}/$unit.service.d/10-yocto.conf <<EOF
[Service]
Environment=ORT_DYLIB_PATH=${libdir}/libonnxruntime.so.1
Environment=GST_PLUGIN_PATH=${libdir}/gstreamer-1.0
EOF
    done
    install -m 0644 ${UNPACKDIR}/20-saha-offline.conf \
        ${D}${systemd_system_unitdir}/updaterd.service.d/
    # ToF is fitted optionally. Its unit is shipped but not enabled by presets.
    install -d ${D}${datadir}/saha/microduck ${D}${sysconfdir}/dbus-1/system.d
    install -m 0644 ${UNPACKDIR}/50-microduck-btd.conf ${D}${sysconfdir}/dbus-1/system.d/
    install -d ${D}${sysconfdir}/udev/rules.d ${D}${sysconfdir}/systemd/journald.conf.d
    install -m 0644 ${UNPACKDIR}/60-microduck-i2c.rules ${D}${sysconfdir}/udev/rules.d/
    install -m 0644 ${UNPACKDIR}/microduck-journal.conf ${D}${sysconfdir}/systemd/journald.conf.d/
    cat > ${D}${datadir}/saha/microduck/runtime-source <<EOF
version=${PV}
revision=${MICRODUCK_SRCREV}
archive_sha256=${MICRODUCK_ARCHIVE_SHA256}
EOF
}

FILES:${PN} = " \
    /opt/robot/daemon ${bindir}/robotctl ${sysconfdir}/robot \
    ${sysconfdir}/dbus-1/system.d/50-microduck-btd.conf \
    ${sysconfdir}/udev/rules.d/60-microduck-i2c.rules \
    ${sysconfdir}/systemd/journald.conf.d/microduck-journal.conf \
    ${systemd_system_unitdir} ${datadir}/saha/microduck \
"
CONFFILES:${PN} += "${sysconfdir}/robot/robotd.toml ${sysconfdir}/robot/updater.toml"
