SUMMARY = "RDK X5 BPU end-to-end HIMLoco inference smoke test"
DESCRIPTION = "Runs D-Robotics' official RDK X5 HIMLoco Go2 policy through the pinned DNN runtime"
LICENSE = "CLOSED"
PR = "r1"

COMPATIBLE_MACHINE = "^rdk-x5$"
PACKAGE_ARCH = "${MACHINE_ARCH}"

SRC_URI = " \
    file://saha-rdk-x5-bpu-smoke.cpp \
    https://archive.d-robotics.cc/downloads/rdk_model_zoo/rdk_x5/himloco/himloco_go2_bayese_1x270.bin;name=model;downloadfilename=himloco_go2_bayese_1x270.bin \
    https://raw.githubusercontent.com/D-Robotics/rdk_model_zoo/7c1eb5393412df1f6d18a97f97c8c086e9ae4b94/samples/robotics/himloco/test_data/obs_history/000000.bin;name=input;downloadfilename=himloco_obs_history_000000.bin \
"
SRC_URI[model.sha256sum] = "7ce46ca2628f8bc236da0e8564180a1de92847bddf1ec00717ce7aa93e8c3e6a"
SRC_URI[input.sha256sum] = "36ddc7317348df8e4ce21c3b0a6500bf411bbc47586703a0607d3120badda847"

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
    install -Dm 0644 ${S}/himloco_go2_bayese_1x270.bin \
        ${D}${datadir}/saha-rdk-x5-bpu-smoke/himloco_go2_bayese_1x270.bin
    install -Dm 0644 ${S}/himloco_obs_history_000000.bin \
        ${D}${datadir}/saha-rdk-x5-bpu-smoke/himloco_obs_history_000000.bin
}
