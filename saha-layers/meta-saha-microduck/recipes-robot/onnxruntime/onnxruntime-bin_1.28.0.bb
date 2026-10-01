SUMMARY = "Pinned official ONNX Runtime ARM64 CPU inference library"
HOMEPAGE = "https://github.com/microsoft/onnxruntime"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=0f7e3b1308cb5c00b372a6e78835732d"
SRC_URI = "https://github.com/microsoft/onnxruntime/releases/download/v${PV}/onnxruntime-linux-aarch64-${PV}.tgz"
SRC_URI[sha256sum] = "e15ff8b5d85afe6c144d97c6fd432254bf76a219daaf17658087d6ecb3e8f0bb"
S = "${UNPACKDIR}/onnxruntime-linux-aarch64-${PV}"

inherit bin_package
COMPATIBLE_HOST = "aarch64.*-linux"
PACKAGE_ARCH = "${TUNE_PKGARCH}"
RDEPENDS:${PN} = "libstdc++ libgcc"
INSANE_SKIP:${PN} = "already-stripped"

do_install() {
    install -d ${D}${libdir} ${D}${datadir}/licenses/${PN}
    install -m 0755 ${S}/lib/libonnxruntime.so.${PV} ${D}${libdir}/
    ln -s libonnxruntime.so.${PV} ${D}${libdir}/libonnxruntime.so.1
    install -m 0755 ${S}/lib/libonnxruntime_providers_shared.so ${D}${libdir}/
    install -m 0644 ${S}/LICENSE ${S}/ThirdPartyNotices.txt ${D}${datadir}/licenses/${PN}/
}
FILES:${PN} = "${libdir}/libonnxruntime.so.* ${libdir}/libonnxruntime_providers_shared.so ${datadir}/licenses/${PN}"
FILES:${PN}-dev = ""
