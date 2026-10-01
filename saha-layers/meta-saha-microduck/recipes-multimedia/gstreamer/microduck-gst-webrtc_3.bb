SUMMARY = "Pinned upstream Microduck WebRTC and RTP GStreamer plugins"
HOMEPAGE = "https://github.com/pollen-robotics/microduck-gst-plugins"
LICENSE = "MPL-2.0 & Apache-2.0"
MICRODUCK_GST_SRCREV = "a9a839f274fb20698d3abc2639a28d75421c5471"
SRCREV_source = "${MICRODUCK_GST_SRCREV}"
SRCREV_FORMAT = "source"
LIC_FILES_CHKSUM = "file://microduck-gst-source/LICENSE;md5=3b83ef96387f14655fc854ddc3c6bd57 \
    file://${COMMON_LICENSE_DIR}/MPL-2.0;md5=815ca599c9df247a0c7f619bab123dad"
SRC_URI = " \
    https://github.com/pollen-robotics/microduck-gst-plugins/releases/download/v${PV}/microduck-gst-plugins-v${PV}-aarch64.tar.gz;name=plugins \
    git://github.com/pollen-robotics/microduck-gst-plugins.git;protocol=https;nobranch=1;name=source;destsuffix=microduck-gst-source \
"
SRC_URI[plugins.sha256sum] = "5cd133133587467b9724fe386639888b40e420517626199049ff52ca0b4e56a9"
S = "${UNPACKDIR}"
inherit bin_package
COMPATIBLE_HOST = "aarch64.*-linux"
PACKAGE_ARCH = "${TUNE_PKGARCH}"
DEPENDS = "glib-2.0 gstreamer1.0 gstreamer1.0-plugins-base gstreamer1.0-plugins-bad"
RDEPENDS:${PN} = "libnice gstreamer1.0-plugins-bad-webrtc gstreamer1.0-plugins-bad-dtls gstreamer1.0-plugins-bad-srtp"
# webrtcsink uses errorignore while discovering encoder output caps.
RDEPENDS:${PN} += "gstreamer1.0-plugins-bad-debugutilsbad"
INSANE_SKIP:${PN} = "already-stripped"

do_install() {
    install -d ${D}${libdir}/gstreamer-1.0 ${D}${datadir}/saha/microduck/gst-source
    # Software encoding works on both BSPs. The kernel-specific MPP plugin is
    # deliberately excluded until its driver/userspace pair is qualified.
    install -m 0755 ${S}/microduck-gst-plugins-v${PV}-aarch64/libgstrswebrtc.so ${D}${libdir}/gstreamer-1.0/
    install -m 0755 ${S}/microduck-gst-plugins-v${PV}-aarch64/libgstrsrtp.so ${D}${libdir}/gstreamer-1.0/
    install -m 0644 ${S}/microduck-gst-plugins-v${PV}-aarch64/MANIFEST ${D}${datadir}/saha/microduck/gst-source/
    cp -R ${S}/microduck-gst-source/patches ${D}${datadir}/saha/microduck/gst-source/
    install -m 0644 ${S}/microduck-gst-source/pins.env ${D}${datadir}/saha/microduck/gst-source/
    printf '%s\n' '${MICRODUCK_GST_SRCREV}' > ${D}${datadir}/saha/microduck/gst-source/source-revision
}
FILES:${PN} = "${libdir}/gstreamer-1.0/*.so ${datadir}/saha/microduck/gst-source"
FILES:${PN}-dev = ""
