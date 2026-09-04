SUMMARY = "Preloaded Home Assistant container image for Saha (aarch64)"
DESCRIPTION = "Installs the official Home Assistant container image as a \
docker-archive tarball for offline docker load on first boot. During build, \
uses a local archive or local Docker image when available, otherwise fetches \
from the registry with skopeo."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

PV = "1.0"

HA_CONTAINER_IMAGE ?= "ghcr.io/home-assistant/home-assistant:stable"
HA_CONTAINER_IMAGE_OS ?= "linux"
HA_CONTAINER_IMAGE_ARCH ?= "arm64"
HA_CONTAINER_IMAGE_BASENAME ?= "homeassistant-container"
HA_CONTAINER_LOCAL_TAR ?= "${DL_DIR}/homeassistant-container.tar"

SRC_URI = " \
    file://README \
    file://fetch-image.sh \
"

DEPENDS = "ca-certificates-native skopeo-native"

PACKAGE_ARCH = "${MACHINE_ARCH}"

INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INSANE_SKIP:${PN} += "already-stripped ldflags dev-so"

addtask fetch_image after do_unpack before do_patch
do_fetch_image[depends] += "ca-certificates-native:do_populate_sysroot skopeo-native:do_populate_sysroot"
do_fetch_image[network] = "1"
do_fetch_image[prefuncs] = "extend_recipe_sysroot"

do_fetch_image() {
    HA_CONTAINER_IMAGE="${HA_CONTAINER_IMAGE}" \
    HA_CONTAINER_IMAGE_OS="${HA_CONTAINER_IMAGE_OS}" \
    HA_CONTAINER_IMAGE_ARCH="${HA_CONTAINER_IMAGE_ARCH}" \
    HA_CONTAINER_LOCAL_TAR="${HA_CONTAINER_LOCAL_TAR}" \
    DL_DIR="${DL_DIR}" \
    SKOPEO_BIN="${STAGING_SBINDIR_NATIVE}/skopeo" \
    sh ${UNPACKDIR}/fetch-image.sh "${WORKDIR}/${HA_CONTAINER_IMAGE_BASENAME}.tar"
}

do_install() {
    install -d ${D}${datadir}/saha/homeassistant
    install -m 0644 ${WORKDIR}/${HA_CONTAINER_IMAGE_BASENAME}.tar \
        ${D}${datadir}/saha/homeassistant/image.tar
}

FILES:${PN} = "${datadir}/saha/homeassistant/image.tar"
