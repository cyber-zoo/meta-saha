SUMMARY = "Pinned Microduck v5 ONNX policy set"
HOMEPAGE = "https://huggingface.co/pollen-robotics/microduck-policies"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://model-card.md;md5=31b74105814562b45aea02c31bc87568 \
    file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "file://model-card.md \
    https://huggingface.co/pollen-robotics/microduck-policies/resolve/v5/alpha_ground_pick.onnx;name=alpha_ground_pick;downloadfilename=microduck-policies-v5-alpha_ground_pick.onnx \
    https://huggingface.co/pollen-robotics/microduck-policies/resolve/v5/alpha_sitstand.onnx;name=alpha_sitstand;downloadfilename=microduck-policies-v5-alpha_sitstand.onnx \
    https://huggingface.co/pollen-robotics/microduck-policies/resolve/v5/alpha_stand.onnx;name=alpha_stand;downloadfilename=microduck-policies-v5-alpha_stand.onnx \
    https://huggingface.co/pollen-robotics/microduck-policies/resolve/v5/alpha_walking.onnx;name=alpha_walking;downloadfilename=microduck-policies-v5-alpha_walking.onnx \
    https://huggingface.co/pollen-robotics/microduck-policies/resolve/v5/ball_kick_left.onnx;name=ball_kick_left;downloadfilename=microduck-policies-v5-ball_kick_left.onnx \
    https://huggingface.co/pollen-robotics/microduck-policies/resolve/v5/ball_kick_right.onnx;name=ball_kick_right;downloadfilename=microduck-policies-v5-ball_kick_right.onnx \
    https://huggingface.co/pollen-robotics/microduck-policies/resolve/v5/manifest.json;name=manifest;downloadfilename=microduck-policies-v5-manifest.json \
    https://huggingface.co/pollen-robotics/microduck-policies/resolve/v5/roller.onnx;name=roller;downloadfilename=microduck-policies-v5-roller.onnx \
    https://huggingface.co/pollen-robotics/microduck-policies/resolve/v5/roller_crouch.onnx;name=roller_crouch;downloadfilename=microduck-policies-v5-roller_crouch.onnx \
    https://huggingface.co/pollen-robotics/microduck-policies/resolve/v5/roulade.onnx;name=roulade;downloadfilename=microduck-policies-v5-roulade.onnx \
    https://huggingface.co/pollen-robotics/microduck-policies/resolve/v5/velstand.onnx;name=velstand;downloadfilename=microduck-policies-v5-velstand.onnx \
"
SRC_URI[alpha_ground_pick.sha256sum] = "ffbf5109982ff999b0ba53afe86b9ae731bbec679d67fb7f8ab4c52152c88872"
SRC_URI[alpha_sitstand.sha256sum] = "c6c40e35e726eabd803d633e090d112994f469921152448367953fbaf9799bc8"
SRC_URI[alpha_stand.sha256sum] = "1569268713e40deea795dd2922dba50d3621e15a872855408b6b1b125b1c094b"
SRC_URI[alpha_walking.sha256sum] = "e36332d383997d51401897734cd3e79cf5038406feddb18b4d57ecfb141daa6c"
SRC_URI[ball_kick_left.sha256sum] = "d6928284dccd3dd61e08bf2f760effa74309fbefd97b2b31afb2a60f526d196a"
SRC_URI[ball_kick_right.sha256sum] = "147a32c388c6b19111b3ac3b550a9a6dc8b8bf267118af4d8c3712522eedb5af"
SRC_URI[manifest.sha256sum] = "622048c2c23ea58942023f66fd16b189a875fd169e88d85beb16ebbe63b20c94"
SRC_URI[roller.sha256sum] = "cf05651d2708a2f9364212e86b866c97a70ace8131c492500105e8f28bf99afd"
SRC_URI[roller_crouch.sha256sum] = "a1a084be240469c76ac9d3fa44d4792f16d4b1da60398b3ecd3cfc5e2244d990"
SRC_URI[roulade.sha256sum] = "3d60da08fc13f29c1b57f41977aa898132c0d60042100149d8e775affcbca32b"
SRC_URI[velstand.sha256sum] = "1c659be55da94bc5753b707de5c6a3e7c49931e05ca3b6991615cef1a8ba9a45"

S = "${UNPACKDIR}"
inherit allarch

do_install() {
    target=${D}/opt/robot/policies/releases/seed-v5
    install -d "$target" ${D}${datadir}/saha/microduck
    for src in ${UNPACKDIR}/microduck-policies-v5-*; do
        filename=${src##*/}
        install -m 0644 "$src" "$target/${filename#microduck-policies-v5-}"
    done
    ln -s releases/seed-v5 ${D}/opt/robot/policies/current
    printf "repo=pollen-robotics/microduck-policies\nversion=v5\n" > "$target/.source"
    install -m 0644 ${UNPACKDIR}/model-card.md ${D}${datadir}/saha/microduck/policy-model-card.md
    cat > ${D}${datadir}/saha/microduck/policy-sha256sums <<EOF
ffbf5109982ff999b0ba53afe86b9ae731bbec679d67fb7f8ab4c52152c88872  /opt/robot/policies/current/alpha_ground_pick.onnx
c6c40e35e726eabd803d633e090d112994f469921152448367953fbaf9799bc8  /opt/robot/policies/current/alpha_sitstand.onnx
1569268713e40deea795dd2922dba50d3621e15a872855408b6b1b125b1c094b  /opt/robot/policies/current/alpha_stand.onnx
e36332d383997d51401897734cd3e79cf5038406feddb18b4d57ecfb141daa6c  /opt/robot/policies/current/alpha_walking.onnx
d6928284dccd3dd61e08bf2f760effa74309fbefd97b2b31afb2a60f526d196a  /opt/robot/policies/current/ball_kick_left.onnx
147a32c388c6b19111b3ac3b550a9a6dc8b8bf267118af4d8c3712522eedb5af  /opt/robot/policies/current/ball_kick_right.onnx
622048c2c23ea58942023f66fd16b189a875fd169e88d85beb16ebbe63b20c94  /opt/robot/policies/current/manifest.json
cf05651d2708a2f9364212e86b866c97a70ace8131c492500105e8f28bf99afd  /opt/robot/policies/current/roller.onnx
a1a084be240469c76ac9d3fa44d4792f16d4b1da60398b3ecd3cfc5e2244d990  /opt/robot/policies/current/roller_crouch.onnx
3d60da08fc13f29c1b57f41977aa898132c0d60042100149d8e775affcbca32b  /opt/robot/policies/current/roulade.onnx
1c659be55da94bc5753b707de5c6a3e7c49931e05ca3b6991615cef1a8ba9a45  /opt/robot/policies/current/velstand.onnx
EOF
}

FILES:${PN} = "/opt/robot/policies ${datadir}/saha/microduck"
