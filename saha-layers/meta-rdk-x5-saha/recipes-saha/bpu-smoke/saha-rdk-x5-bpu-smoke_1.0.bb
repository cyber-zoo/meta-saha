SUMMARY = "RDK X5 BPU end-to-end inference smoke test"
DESCRIPTION = "Runs one official X5 MobileNetV1 BPU model through the pinned D-Robotics DNN runtime"
LICENSE = "CLOSED"

COMPATIBLE_MACHINE = "^rdk-x5$"
PACKAGE_ARCH = "${MACHINE_ARCH}"

SRC_URI = " \
    file://saha-rdk-x5-bpu-smoke.cpp \
    https://archive.d-robotics.cc/downloads/rdk_model_zoo/rdk_x5/mobilenetv1_224x224_nv12.bin;name=model;downloadfilename=mobilenetv1_224x224_nv12.bin \
"
SRC_URI[model.sha256sum] = "75e5352af729a30baa87b663588aed1c4bf7813dcffcc7b65f1bad6cb5239dca"

S = "${UNPACKDIR}"

# hobot-dnn is intentionally coupled to the RDKOS 3.5.0 / Linux 6.1.83 BSP;
# hobot-bpu-driver supplies the matching bpu_hw_io_x5 kernel module at runtime.
DEPENDS = "hobot-dnn"
RDEPENDS:${PN} = "hobot-dnn hobot-bpu-driver"

do_compile() {
    ${CXX} ${CPPFLAGS} ${CXXFLAGS} ${LDFLAGS} \
        -std=c++17 \
        -I${STAGING_INCDIR} \
        -L${RECIPE_SYSROOT}/usr/hobot/lib \
        -Wl,-rpath,/usr/hobot/lib \
        -Wl,-rpath-link,${RECIPE_SYSROOT}/usr/hobot/lib \
        ${S}/saha-rdk-x5-bpu-smoke.cpp \
        -ldnn \
        -o saha-rdk-x5-bpu-smoke
}

do_install() {
    install -Dm 0755 saha-rdk-x5-bpu-smoke ${D}${bindir}/saha-rdk-x5-bpu-smoke
    install -Dm 0644 ${S}/mobilenetv1_224x224_nv12.bin \
        ${D}${datadir}/saha-rdk-x5-bpu-smoke/mobilenetv1_224x224_nv12.bin
}
