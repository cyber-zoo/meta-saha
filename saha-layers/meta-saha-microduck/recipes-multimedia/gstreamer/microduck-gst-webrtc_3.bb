SUMMARY = "Pinned upstream Microduck WebRTC and RTP GStreamer plugins"
HOMEPAGE = "https://github.com/pollen-robotics/microduck-gst-plugins"
LICENSE = "MPL-2.0 & Apache-2.0"
LIC_FILES_CHKSUM = "file://microduck-gst-plugins-${PV}/LICENSE;md5=86d3f3a95c324c9479bd8986968f4327 \
    file://${COMMON_LICENSE_DIR}/MPL-2.0;md5=815ca599c9df247a0c7f619bab123dad"
SRC_URI = " \
    https://github.com/pollen-robotics/microduck-gst-plugins/releases/download/v${PV}/microduck-gst-plugins-v${PV}-aarch64.tar.gz;name=plugins \
    https://codeload.github.com/pollen-robotics/microduck-gst-plugins/tar.gz/refs/tags/v${PV};name=source;downloadfilename=microduck-gst-source-v${PV}.tar.gz \
"
SRC_URI[plugins.sha256sum] = "5cd133133587467b9724fe386639888b40e420517626199049ff52ca0b4e56a9"
SRC_URI[source.sha256sum] = "5c90fe7836972dd4ab2b050a6246d9af7ff6750a9833a5a9d5807b05dcd1b75a"
S = "${UNPACKDIR}"
inherit bin_package
COMPATIBLE_HOST = "aarch64.*-linux"
PACKAGE_ARCH = "${TUNE_PKGARCH}"
DEPENDS = "glib-2.0 gstreamer1.0 gstreamer1.0-plugins-base gstreamer1.0-plugins-bad"
RDEPENDS:${PN} = "libnice gstreamer1.0-plugins-bad-webrtc gstreamer1.0-plugins-bad-dtls gstreamer1.0-plugins-bad-srtp"
INSANE_SKIP:${PN} = "already-stripped"

do_install() {
    install -d ${D}${libdir}/gstreamer-1.0 ${D}${datadir}/saha/microduck/gst-source
    # Software encoding works on both BSPs. The kernel-specific MPP plugin is
    # deliberately excluded until its driver/userspace pair is qualified.
    install -m 0755 ${S}/microduck-gst-plugins-v${PV}-aarch64/libgstrswebrtc.so ${D}${libdir}/gstreamer-1.0/
    install -m 0755 ${S}/microduck-gst-plugins-v${PV}-aarch64/libgstrsrtp.so ${D}${libdir}/gstreamer-1.0/
    install -m 0644 ${S}/microduck-gst-plugins-v${PV}-aarch64/MANIFEST ${D}${datadir}/saha/microduck/gst-source/
    cp -R ${S}/microduck-gst-plugins-${PV}/patches ${D}${datadir}/saha/microduck/gst-source/
    install -m 0644 ${S}/microduck-gst-plugins-${PV}/pins.env ${D}${datadir}/saha/microduck/gst-source/
}
FILES:${PN} = "${libdir}/gstreamer-1.0/*.so ${datadir}/saha/microduck/gst-source"
FILES:${PN}-dev = ""
