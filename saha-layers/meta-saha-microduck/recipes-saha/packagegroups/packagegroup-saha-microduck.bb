SUMMARY = "Microduck control, radio, audio and WebRTC runtime"
LICENSE = "MIT"
inherit packagegroup

RDEPENDS:${PN} = " \
    microduck-runtime \
    alsa-utils \
    avahi-daemon \
    bluez5 \
    i2c-tools \
    python3-core \
    gstreamer1.0 \
    gstreamer1.0-plugins-base-meta \
    gstreamer1.0-plugins-good-meta \
    gstreamer1.0-plugins-bad-videoparsersbad \
    gstreamer1.0-plugins-bad-sctp \
    gstreamer1.0-plugins-ugly-x264 \
"
