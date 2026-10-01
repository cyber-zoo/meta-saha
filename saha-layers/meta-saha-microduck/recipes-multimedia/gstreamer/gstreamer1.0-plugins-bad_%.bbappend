# Keep the headless media closure focused; the upstream default also builds
# GUI/vector-rendering plugins that need a Rust/LLVM toolchain.
PACKAGECONFIG = "${GSTREAMER_ORC} dtls openssl opusparse srtp sctp webrtc"
