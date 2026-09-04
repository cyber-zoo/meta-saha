#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd -P)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

contains() {
  local haystack=$1
  local needle=$2
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

targets_output="$("$ROOT_DIR/scripts/saha-targets")"
contains "$targets_output" "orin-nx-16g-p3768"
contains "$targets_output" "p3768-0000-p3767-0000"
contains "$targets_output" "agx-thor-devkit"
contains "$targets_output" "jetson-agx-thor-devkit"
contains "$targets_output" "agx-orin-devkit"
contains "$targets_output" "jetson-agx-orin-devkit"
contains "$targets_output" "rdk-x5"
contains "$targets_output" "D-Robotics RDK X5"
contains "$targets_output" "iq-9075-evk"
contains "$targets_output" "Qualcomm Dragonwing IQ-9075"
if [[ "$targets_output" == *"ros"* ]] || [[ "$targets_output" == *"ROS"* ]]; then
  fail "supported target list must not include ROS targets"
fi

dry_run_output="$(SAHA_DRY_RUN=1 "$ROOT_DIR/scripts/saha-build" orin-nx-16g-p3768)"
contains "$dry_run_output" "DOCKER_CONFIG="
contains "$dry_run_output" "BUILDX_CONFIG="
contains "$dry_run_output" "docker image inspect"
contains "$dry_run_output" "meta-saha-yocto-builder:wrynose"
contains "$dry_run_output" "kas build kas/targets/orin-nx-16g-p3768.yml:kas/include/ros-distro-jazzy.yml:kas/include/homeassistant-container.yml"
contains "$dry_run_output" "/work/build/orin-nx-16g-p3768"
contains "$dry_run_output" "KAS_WORK_DIR=/work/build/orin-nx-16g-p3768"
contains "$dry_run_output" "GIT_HTTP_VERSION=HTTP/1.1"
contains "$dry_run_output" "GIT_CONFIG_COUNT=1"
contains "$dry_run_output" "GIT_CONFIG_KEY_0=http.version"
contains "$dry_run_output" "GIT_CONFIG_VALUE_0=HTTP/1.1"
contains "$dry_run_output" "SAHA_BB_NUMBER_THREADS=4"
contains "$dry_run_output" "SAHA_BB_NUMBER_PARSE_THREADS=4"
contains "$dry_run_output" "SAHA_PARALLEL_MAKE=-j\\ 4"
contains "$dry_run_output" "/work/downloads"
contains "$dry_run_output" "/work/sstate-cache"
if [[ "$dry_run_output" == *" -it "* ]]; then
  fail "non-interactive build command should not allocate a TTY"
fi

qcom_dry_run_output="$(SAHA_DRY_RUN=1 "$ROOT_DIR/scripts/saha-build" iq-9075-evk)"
contains "$qcom_dry_run_output" "kas build kas/targets/iq-9075-evk.yml:kas/include/homeassistant-container.yml"
contains "$qcom_dry_run_output" "/work/build/iq-9075-evk"
contains "$qcom_dry_run_output" "KAS_WORK_DIR=/work/build/iq-9075-evk"
contains "$qcom_dry_run_output" "/work/downloads"
contains "$qcom_dry_run_output" "/work/sstate-cache"
if [[ "$qcom_dry_run_output" == *"tegra"* ]] || [[ "$qcom_dry_run_output" == *"meta-d-robotics"* ]]; then
  fail "IQ-9075 Docker command must not select another BSP graph"
fi

if SAHA_DRY_RUN=1 SAHA_ROS_DISTRO=lyrical "$ROOT_DIR/scripts/saha-build" iq-9075-evk >/tmp/saha-iq-9075-lyrical.out 2>&1; then
  fail "IQ-9075 unexpectedly accepted ROS 2 Lyrical"
fi
contains "$(cat /tmp/saha-iq-9075-lyrical.out)" "IQ-9075 EVK supports only ROS 2 Jazzy"

if SAHA_DRY_RUN=1 SAHA_X5_ACCELERATORS=1 "$ROOT_DIR/scripts/saha-build" iq-9075-evk >/tmp/saha-iq-9075-x5.out 2>&1; then
  fail "IQ-9075 unexpectedly accepted the RDK X5 accelerator switch"
fi
contains "$(cat /tmp/saha-iq-9075-x5.out)" "SAHA_X5_ACCELERATORS is supported only for rdk-x5"

rdk_bsp_dir="$(mktemp -d)"
rdk_dry_run_output="$(
  SAHA_DRY_RUN=1 \
  SAHA_META_D_ROBOTICS_DIR="$rdk_bsp_dir" \
  "$ROOT_DIR/scripts/saha-build" rdk-x5
)"
contains "$rdk_dry_run_output" "kas build kas/targets/rdk-x5.yml"
contains "$rdk_dry_run_output" "/work/build/rdk-x5"
contains "$rdk_dry_run_output" "KAS_WORK_DIR=/work/build/rdk-x5"
contains "$rdk_dry_run_output" ":/work/meta-d-robotics:ro"
rmdir "$rdk_bsp_dir"

rdk_accelerator_bsp_dir="$(mktemp -d)"
rdk_accelerator_dry_run_output="$(
  SAHA_DRY_RUN=1 \
  SAHA_X5_ACCELERATORS=1 \
  SAHA_META_D_ROBOTICS_DIR="$rdk_accelerator_bsp_dir" \
  "$ROOT_DIR/scripts/saha-build" rdk-x5
)"
contains "$rdk_accelerator_dry_run_output" "kas build kas/targets/rdk-x5.yml:kas/include/rdk-x5-accelerators.yml"
contains "$rdk_accelerator_dry_run_output" "/work/build/rdk-x5-accelerators"
contains "$rdk_accelerator_dry_run_output" "KAS_WORK_DIR=/work/build/rdk-x5-accelerators"
rmdir "$rdk_accelerator_bsp_dir"

if SAHA_DRY_RUN=1 SAHA_X5_ACCELERATORS=1 "$ROOT_DIR/scripts/saha-build" orin-nx-16g-p3768 >/tmp/saha-x5-accelerators-jetson.out 2>&1; then
  fail "Jetson unexpectedly accepted the RDK X5 accelerator switch"
fi
contains "$(cat /tmp/saha-x5-accelerators-jetson.out)" "SAHA_X5_ACCELERATORS is supported only for rdk-x5"

if SAHA_DRY_RUN=1 SAHA_X5_ACCELERATORS=yes SAHA_META_D_ROBOTICS_DIR="$ROOT_DIR" "$ROOT_DIR/scripts/saha-build" rdk-x5 >/tmp/saha-x5-accelerators-invalid.out 2>&1; then
  fail "RDK X5 unexpectedly accepted an invalid accelerator switch"
fi
contains "$(cat /tmp/saha-x5-accelerators-invalid.out)" "SAHA_X5_ACCELERATORS must be 0 or 1"

if SAHA_DRY_RUN=1 "$ROOT_DIR/scripts/saha-build" rdk-x5 >/tmp/saha-rdk-x5-missing-layer.out 2>&1; then
  fail "RDK X5 build unexpectedly succeeded without its BSP layer"
fi
contains "$(cat /tmp/saha-rdk-x5-missing-layer.out)" "SAHA_META_D_ROBOTICS_DIR must point to meta-d-robotics"

if SAHA_DRY_RUN=1 SAHA_ROS_DISTRO=lyrical "$ROOT_DIR/scripts/saha-build" rdk-x5 >/tmp/saha-rdk-x5-lyrical.out 2>&1; then
  fail "RDK X5 unexpectedly accepted ROS 2 Lyrical"
fi
contains "$(cat /tmp/saha-rdk-x5-lyrical.out)" "RDK X5 supports only ROS 2 Jazzy"

tuning_dry_run_output="$(
  env \
    SAHA_DRY_RUN=1 \
    SAHA_BB_NUMBER_THREADS=2 \
    SAHA_BB_NUMBER_PARSE_THREADS=3 \
    SAHA_PARALLEL_MAKE="-j 6" \
    "$ROOT_DIR/scripts/saha-build" orin-nx-16g-p3768
)"
contains "$tuning_dry_run_output" "SAHA_BB_NUMBER_THREADS=2"
contains "$tuning_dry_run_output" "SAHA_BB_NUMBER_PARSE_THREADS=3"
contains "$tuning_dry_run_output" "SAHA_PARALLEL_MAKE=-j\\ 6"

lyrical_dry_run_output="$(
  env \
    SAHA_DRY_RUN=1 \
    SAHA_ROS_DISTRO=lyrical \
    "$ROOT_DIR/scripts/saha-build" orin-nx-16g-p3768
)"
contains "$lyrical_dry_run_output" "kas build kas/targets/orin-nx-16g-p3768.yml:kas/include/ros-distro-lyrical.yml:kas/include/homeassistant-container.yml"
contains "$lyrical_dry_run_output" "/build/orin-nx-16g-p3768-ros-lyrical:/work/build/orin-nx-16g-p3768"

no_ha_dry_run_output="$(
  env \
    SAHA_DRY_RUN=1 \
    SAHA_HOMEASSISTANT=0 \
    "$ROOT_DIR/scripts/saha-build" orin-nx-16g-p3768
)"
contains "$no_ha_dry_run_output" "kas build kas/targets/orin-nx-16g-p3768.yml:kas/include/ros-distro-jazzy.yml"
if [[ "$no_ha_dry_run_output" == *"homeassistant-container.yml"* ]]; then
  fail "SAHA_HOMEASSISTANT=0 must omit the Home Assistant kas include"
fi

if SAHA_HOMEASSISTANT=maybe "$ROOT_DIR/scripts/saha-build" orin-nx-16g-p3768 >/tmp/saha-invalid-ha.out 2>&1; then
  fail "invalid SAHA_HOMEASSISTANT values must be rejected"
fi
grep -q 'Unsupported SAHA_HOMEASSISTANT value' /tmp/saha-invalid-ha.out ||
  fail "invalid SAHA_HOMEASSISTANT values must report a clear error"

! grep -q 'kas/include/homeassistant-container.yml' "$ROOT_DIR/kas/include/base.yml" ||
  fail "Home Assistant kas include must be selected by SAHA_HOMEASSISTANT, not base.yml"

if [ ! -f "$ROOT_DIR/kas/include/homeassistant-container.yml" ]; then
  fail "Home Assistant kas include must exist"
fi
COMMON_LAYER="$ROOT_DIR/saha-layers/meta-saha-common"

if [ ! -f "$COMMON_LAYER/recipes-saha/homeassistant-container/saha-homeassistant-container.bb" ]; then
  fail "Home Assistant container recipe must exist"
fi
grep -q 'Requires=docker.service' \
  "$COMMON_LAYER/recipes-saha/homeassistant-container/saha-homeassistant-container/homeassistant-container.service" ||
  fail "Home Assistant systemd unit must depend on docker.service"
grep -q 'ghcr.io/home-assistant/home-assistant:stable' \
  "$COMMON_LAYER/recipes-saha/homeassistant-container/saha-homeassistant-container/saha-homeassistant-container.env" ||
  fail "Home Assistant default image must use the official container"
grep -q 'packagegroup-saha-homeassistant-container' \
  "$ROOT_DIR/kas/include/homeassistant-container.yml" ||
  fail "Home Assistant kas include must install the packagegroup"
grep -q 'saha-homeassistant-container-image' \
  "$COMMON_LAYER/recipes-saha/packagegroups/packagegroup-saha-homeassistant-container.bb" ||
  fail "Home Assistant packagegroup must include the preloaded image recipe"
grep -q 'docker load -i' \
  "$COMMON_LAYER/recipes-saha/homeassistant-container/saha-homeassistant-container/saha-homeassistant-container.sh" ||
  fail "Home Assistant launcher must load the preloaded docker archive"
grep -q 'SAHA_HOMEASSISTANT_PULL=0' \
  "$COMMON_LAYER/recipes-saha/homeassistant-container/saha-homeassistant-container/saha-homeassistant-container.env" ||
  fail "Home Assistant defaults must prefer the preloaded image over docker pull"
grep -q 'docker save' \
  "$COMMON_LAYER/recipes-saha/homeassistant-container/saha-homeassistant-container-image/fetch-image.sh" ||
  fail "Home Assistant fetch script must support local docker save"
grep -q 'homeassistant-container.tar' \
  "$COMMON_LAYER/recipes-saha/homeassistant-container/saha-homeassistant-container-image/fetch-image.sh" ||
  fail "Home Assistant fetch script must support local tarball cache"
grep -q 'image_loaded' \
  "$COMMON_LAYER/recipes-saha/homeassistant-container/saha-homeassistant-container/saha-homeassistant-container.sh" ||
  fail "Home Assistant launcher must prefer an existing local docker image"
grep -q 'HA_CONTAINER_LOCAL_TAR' \
  "$ROOT_DIR/kas/include/homeassistant-container.yml" ||
  fail "Home Assistant kas include must define a local tarball cache path"
grep -q 'wait-docker' \
  "$COMMON_LAYER/recipes-saha/homeassistant-container/saha-homeassistant-container/saha-homeassistant-container.sh" ||
  fail "Home Assistant launcher must wait for docker"
grep -q 'multi-user.target.wants/homeassistant-container.service' \
  "$COMMON_LAYER/recipes-saha/homeassistant-container/saha-homeassistant-container.bb" ||
  fail "Home Assistant launcher must enable systemd service at install time"
grep -q 'IMAGE_ROOTFS_EXTRA_SPACE' \
  "$ROOT_DIR/kas/include/homeassistant-container.yml" ||
  fail "Home Assistant kas include must reserve extra rootfs space"
grep -q 'IMAGE_INSTALL:append:pn-saha-image-robot' \
  "$ROOT_DIR/kas/include/homeassistant-container.yml" ||
  fail "Home Assistant kas include must scope packagegroup to saha-image-robot only"

proxy_dry_run_output="$(
  env \
    SAHA_DRY_RUN=1 \
    SAHA_LOAD_ZSHRC_PROXY=0 \
    HTTP_PROXY=http://proxy.example.invalid:3128 \
    no_proxy=localhost,127.0.0.1 \
    "$ROOT_DIR/scripts/saha-build" orin-nx-16g-p3768
)"
contains "$proxy_dry_run_output" "--build-arg HTTP_PROXY"
contains "$proxy_dry_run_output" "--build-arg no_proxy"
contains "$proxy_dry_run_output" "-e HTTP_PROXY"
contains "$proxy_dry_run_output" "-e no_proxy"
if [[ "$proxy_dry_run_output" == *"proxy.example.invalid"* ]]; then
  fail "dry-run output must not expose proxy values"
fi

no_proxy_dry_run_output="$(
  env \
    SAHA_DRY_RUN=1 \
    SAHA_NO_PROXY=1 \
    HTTP_PROXY=http://proxy.example.invalid:3128 \
    HTTPS_PROXY=http://proxy.example.invalid:3128 \
    "$ROOT_DIR/scripts/saha-build" orin-nx-16g-p3768
)"
contains "$no_proxy_dry_run_output" "-e HTTP_PROXY="
contains "$no_proxy_dry_run_output" "-e HTTPS_PROXY="
contains "$no_proxy_dry_run_output" "-e http_proxy="
contains "$no_proxy_dry_run_output" "-e https_proxy="
if [[ "$no_proxy_dry_run_output" == *"--build-arg HTTP_PROXY"* ]] ||
   [[ "$no_proxy_dry_run_output" == *"proxy.example.invalid"* ]]; then
  fail "SAHA_NO_PROXY must disable proxy propagation and hide proxy values"
fi

loopback_proxy_dry_run_output="$(
  env \
    SAHA_DRY_RUN=1 \
    SAHA_LOAD_ZSHRC_PROXY=0 \
    HTTPS_PROXY=http://127.0.0.1:3128 \
    all_proxy=socks5://localhost:1080 \
    "$ROOT_DIR/scripts/saha-build" orin-nx-16g-p3768
)"
contains "$loopback_proxy_dry_run_output" "--network host"
contains "$loopback_proxy_dry_run_output" "--build-arg HTTPS_PROXY"
contains "$loopback_proxy_dry_run_output" "-e HTTPS_PROXY"
if [[ "$loopback_proxy_dry_run_output" == *"127.0.0.1"* ]] ||
   [[ "$loopback_proxy_dry_run_output" == *"localhost:1080"* ]]; then
  fail "loopback proxy dry-run output must not expose proxy values"
fi

if command -v zsh >/dev/null 2>&1; then
  tmp_home="$(mktemp -d)"
  cat >"$tmp_home/.zshrc" <<'ZSHRC'
export HTTPS_PROXY=http://zsh-proxy.example.invalid:3128
export all_proxy=socks5://zsh-socks.example.invalid:1080
ZSHRC
  zsh_proxy_output="$(
    env -i \
      PATH="$PATH" \
      HOME="$tmp_home" \
      SAHA_DRY_RUN=1 \
      "$ROOT_DIR/scripts/saha-build" agx-orin-devkit
  )"
  contains "$zsh_proxy_output" "--build-arg HTTPS_PROXY"
  contains "$zsh_proxy_output" "--build-arg all_proxy"
  contains "$zsh_proxy_output" "-e HTTPS_PROXY"
  contains "$zsh_proxy_output" "-e all_proxy"
  if [[ "$zsh_proxy_output" == *"zsh-proxy.example.invalid"* ]] ||
     [[ "$zsh_proxy_output" == *"zsh-socks.example.invalid"* ]]; then
    fail "zshrc-loaded proxy values must not appear in dry-run output"
  fi
  zsh_proxy_with_no_proxy_output="$(
    env -i \
      PATH="$PATH" \
      HOME="$tmp_home" \
      NO_PROXY=localhost \
      SAHA_DRY_RUN=1 \
      "$ROOT_DIR/scripts/saha-build" agx-orin-devkit
  )"
  contains "$zsh_proxy_with_no_proxy_output" "--build-arg HTTPS_PROXY"
  contains "$zsh_proxy_with_no_proxy_output" "--build-arg NO_PROXY"
  rm -rf "$tmp_home"
fi

if "$ROOT_DIR/scripts/saha-build" invalid-target >/tmp/saha-invalid-target.out 2>&1; then
  fail "invalid target unexpectedly succeeded"
fi
contains "$(cat /tmp/saha-invalid-target.out)" "Unsupported target: invalid-target"

if SAHA_ROS_DISTRO=humble "$ROOT_DIR/scripts/saha-build" orin-nx-16g-p3768 >/tmp/saha-invalid-ros.out 2>&1; then
  fail "invalid ROS distro unexpectedly succeeded"
fi
contains "$(cat /tmp/saha-invalid-ros.out)" "Unsupported ROS distro: humble"
contains "$(cat /tmp/saha-invalid-ros.out)" "Supported ROS distros:"

for ignored in ".docker-cache" "build" "downloads" "sstate-cache" "repos"; do
  grep -qxF "$ignored" "$ROOT_DIR/.dockerignore" || fail ".dockerignore missing $ignored"
done

grep -A4 '^  bitbake:' "$ROOT_DIR/kas/include/repos-wrynose.yml" |
  grep -qxF '    branch: "2.18"' ||
  fail "bitbake must use the Wrynose-compatible 2.18 branch"

grep -A3 '^  meta-saha:' "$ROOT_DIR/kas/include/repos-wrynose.yml" |
  grep -qxF '    path: /work/meta-saha' ||
  fail "local meta-saha repo path must match the Docker mount point"

if grep -q '^  meta-ros:' "$ROOT_DIR/kas/include/repos-wrynose.yml"; then
  fail "base Wrynose repo graph must not hard-code one ROS distro layer"
fi
for ros_distro in jazzy lyrical; do
  ros_include="$ROOT_DIR/kas/include/ros-distro-$ros_distro.yml"
  [ -f "$ros_include" ] || fail "ROS distro kas include missing: $ros_include"
  grep -A10 '^  meta-ros:' "$ros_include" |
    grep -qxF '    url: https://github.com/ros/meta-ros.git' ||
    fail "ROS distro kas include must define meta-ros: $ros_include"
  grep -A10 '^  meta-ros:' "$ros_include" |
    grep -qxF '    branch: wrynose' ||
    fail "ROS distro kas include must pin the Wrynose branch: $ros_include"
  grep -A10 '^  meta-ros:' "$ros_include" |
    grep -qxF "      meta-ros2-$ros_distro:" ||
    fail "ROS distro kas include must select meta-ros2-$ros_distro"
done
grep -q 'ROS_WORLD_SKIP_GROUPS:append = " zenoh"' "$ROOT_DIR/kas/include/ros-distro-lyrical.yml" ||
  fail "Lyrical builds must skip the zenoh group unless meta-zenoh is added"

QCOM_LAYER="$ROOT_DIR/saha-layers/meta-qcom-saha"
QCOM_REPOS="$ROOT_DIR/kas/include/repos-qcom-wrynose.yml"
QCOM_BASE="$ROOT_DIR/kas/include/qcom-base.yml"
QCOM_TARGET="$ROOT_DIR/kas/targets/iq-9075-evk.yml"
[ -f "$QCOM_LAYER/conf/layer.conf" ] || fail "IQ-9075 Saha layer configuration must exist"
[ -f "$QCOM_LAYER/conf/distro/saha-qcom.conf" ] || fail "IQ-9075 distro configuration must exist"
[ -f "$QCOM_LAYER/recipes-saha/images/saha-image-robot.bb" ] || fail "IQ-9075 image recipe must exist"
[ -f "$QCOM_REPOS" ] || fail "IQ-9075 kas repository graph must exist"
[ -f "$QCOM_BASE" ] || fail "IQ-9075 kas base configuration must exist"
[ -f "$QCOM_TARGET" ] || fail "IQ-9075 kas target configuration must exist"
grep -qxF '    commit: ef022bf82d79015802309d14c28b13373ebe53f5' "$QCOM_REPOS" ||
  fail "IQ-9075 graph must pin OpenEmbedded-Core"
grep -qxF '    commit: 0ad6c1c34a5e07a5f8dd66ab248c1e7b37b69fa9' "$QCOM_REPOS" ||
  fail "IQ-9075 graph must pin BitBake"
grep -qxF '    commit: 8bfc4ae8cf7fc835a23d7a27830f866617d9808f' "$QCOM_REPOS" ||
  fail "IQ-9075 graph must pin meta-lts-mixins"
grep -qxF '    commit: bfe2312f021a6ca390e5205f77195a1d5af30aa5' "$QCOM_REPOS" ||
  fail "IQ-9075 graph must pin meta-qcom"
grep -A6 '^  meta-saha:' "$QCOM_REPOS" |
  grep -qxF '      saha-layers/meta-saha-common:' ||
  fail "IQ-9075 graph must consume the shared Saha layer"
grep -A6 '^  meta-saha:' "$QCOM_REPOS" |
  grep -qxF '      saha-layers/meta-qcom-saha:' ||
  fail "IQ-9075 graph must consume the QCOM Saha layer"
grep -qxF 'distro: saha-qcom' "$QCOM_BASE" ||
  fail "IQ-9075 graph must select the QCOM Saha distro"
grep -qxF 'machine: iq-9075-evk' "$QCOM_TARGET" ||
  fail "IQ-9075 target must select the standard EVK machine"
grep -q 'qcom_scm.download_mode=1' "$QCOM_BASE" ||
  fail "IQ-9075 image must preserve the QCOM download-mode kernel argument"
grep -q 'git.codelinaro.org/clo/yocto-mirrors/github' "$QCOM_BASE" ||
  fail "IQ-9075 graph must retain the upstream Qualcomm Git mirror route"
grep -q 'artifacts.codelinaro.org/codelinaro-le' "$QCOM_BASE" ||
  fail "IQ-9075 graph must retain the upstream Qualcomm artifact mirror route"
if rg -n 'meta-tegra|meta-d-robotics|iq-9075-evk-open-fw' "$QCOM_REPOS" "$QCOM_BASE" "$QCOM_TARGET"; then
  fail "IQ-9075 graph must remain isolated from other BSPs and open-fw variant"
fi

grep -q 'EXTRA_IMAGE_FEATURES ?= "empty-root-password allow-root-login"' "$ROOT_DIR/kas/include/base.yml" ||
  fail "Wrynose image features must not use removed debug-tweaks alias"

OPENSSH_APPEND="$COMMON_LAYER/recipes-connectivity/openssh/openssh_%.bbappend"
[ -f "$OPENSSH_APPEND" ] ||
  fail "openssh bbappend must exist for SSH root empty-password access"
grep -q 'PermitEmptyPasswords yes' "$COMMON_LAYER/recipes-connectivity/openssh/openssh/99-saha-root-empty-password.conf" ||
  fail "OpenSSH must explicitly permit empty passwords for root SSH access"

grep -q 'BB_HASHSERVE_DB_DIR ?= "${SSTATE_DIR}"' "$ROOT_DIR/kas/include/base.yml" ||
  fail "shared sstate builds should also share hash equivalence database"

grep -q 'PREFERRED_PROVIDER_edk2-nvidia-standalone-mm = "edk2-nvidia-standalone-mm-prebuilt"' "$ROOT_DIR/kas/include/base.yml" ||
  fail "default BSP build should use OE4T prebuilt standalone-mm provider"

RDK_REPOS="$ROOT_DIR/kas/include/repos-rdk-x5-wrynose.yml"
RDK_BASE="$ROOT_DIR/kas/include/rdk-x5-base.yml"
RDK_TARGET="$ROOT_DIR/kas/targets/rdk-x5.yml"
RDK_ACCELERATORS="$ROOT_DIR/kas/include/rdk-x5-accelerators.yml"
[ -f "$RDK_REPOS" ] || fail "RDK X5 kas repository graph must exist"
[ -f "$RDK_BASE" ] || fail "RDK X5 kas base configuration must exist"
[ -f "$RDK_TARGET" ] || fail "RDK X5 kas target configuration must exist"
[ -f "$RDK_ACCELERATORS" ] || fail "RDK X5 accelerator kas overlay must exist"
grep -A6 '^  openembedded-core:' "$RDK_REPOS" |
  grep -qxF '    commit: 5d1aa5c806c061a2994f4decb59016610f093213' ||
  fail "RDK X5 graph must pin OpenEmbedded-Core"
grep -A6 '^  bitbake:' "$RDK_REPOS" |
  grep -qxF '    commit: acfe02fa38b5da9e6a36c6cedcf91d4fcbefbfbd' ||
  fail "RDK X5 graph must pin BitBake"
grep -A6 '^  meta-openembedded:' "$RDK_REPOS" |
  grep -qxF '    commit: 100027977216601000cbefc42c2ff6cf667e7b5e' ||
  fail "RDK X5 graph must pin meta-openembedded"
grep -A6 '^  meta-ros:' "$RDK_REPOS" |
  grep -qxF '    commit: dbb05e0b4430cd26dc2a9973cc4d70bb46d6b354' ||
  fail "RDK X5 graph must pin meta-ros"
grep -A4 '^  meta-d-robotics:' "$RDK_REPOS" |
  grep -qxF '    path: /work/meta-d-robotics' ||
  fail "RDK X5 graph must use the Docker-mounted BSP layer"
grep -A4 '^  meta-saha:' "$RDK_REPOS" |
  grep -qxF '      saha-layers/meta-rdk-x5-saha:' ||
  fail "RDK X5 graph must select its isolated Saha layer"
if rg -n '^[[:space:]]*(meta-tegra:|distro:[[:space:]]+tegra-saha)' "$RDK_REPOS" "$RDK_BASE" "$RDK_TARGET"; then
  fail "RDK X5 kas graph must not include Tegra metadata"
fi
grep -qxF 'distro: saha-rdk-x5' "$RDK_BASE" ||
  fail "RDK X5 graph must select the RDK-specific distro"
grep -qxF 'machine: rdk-x5' "$RDK_TARGET" ||
  fail "RDK X5 target must select the RDK X5 machine"
grep -qxF '    CORE_IMAGE_BASE_INSTALL:append = " packagegroup-rdk-x5-accelerators saha-rdk-x5-bpu-smoke"' "$RDK_ACCELERATORS" ||
  fail "RDK X5 accelerator overlay must install the accelerator packagegroup and BPU smoke test"

RDK_LAYER="$ROOT_DIR/saha-layers/meta-rdk-x5-saha"
RDK_IMAGE="$RDK_LAYER/recipes-saha/images/saha-image-robot.bb"
RDK_WKS="$RDK_LAYER/recipes-saha/images/rdk-x5.wks.in"
RDK_BASE_GROUP="$RDK_LAYER/recipes-saha/packagegroups/packagegroup-saha-rdk-x5-base.bb"
RDK_NETWORK_GROUP="$RDK_LAYER/recipes-saha/packagegroups/packagegroup-saha-rdk-x5-network.bb"
RDK_BPU_SMOKE="$RDK_LAYER/recipes-saha/bpu-smoke/saha-rdk-x5-bpu-smoke_1.0.bb"
RDK_BPU_SMOKE_SOURCE="$RDK_LAYER/recipes-saha/bpu-smoke/files/saha-rdk-x5-bpu-smoke.cpp"
RDK_NETWORK_RECIPE="$RDK_LAYER/recipes-connectivity/systemd-networkd/saha-rdk-x5-network_1.0.bb"
RDK_NETWORK_PROFILE="$RDK_LAYER/recipes-connectivity/systemd-networkd/saha-rdk-x5-network/20-saha-eth0.network"
RDK_NETWORKMANAGER_APPEND="$RDK_LAYER/recipes-connectivity/networkmanager/networkmanager_%.bbappend"
RDK_NETWORKMANAGER_POLICY="$RDK_LAYER/recipes-connectivity/networkmanager/networkmanager/99-saha-rdk-x5-unmanaged-devices.conf"
RDK_NETWORKMANAGER_ORDERING="$RDK_LAYER/recipes-connectivity/networkmanager/networkmanager/10-rdk-x5-wifi.conf"
RDK_HOBOT_WIFI_APPEND="$RDK_LAYER/recipes-d-robotics/wireless/hobot-wifi_%.bbappend"
[ -f "$RDK_LAYER/conf/layer.conf" ] || fail "RDK X5 Saha layer configuration must exist"
[ -f "$RDK_LAYER/conf/distro/saha-rdk-x5.conf" ] || fail "RDK X5 distro configuration must exist"
[ -f "$RDK_IMAGE" ] || fail "RDK X5 robot image recipe must exist"
[ -f "$RDK_WKS" ] || fail "RDK X5 WIC layout must exist"
[ -f "$RDK_BASE_GROUP" ] || fail "RDK X5 base packagegroup must exist"
[ -f "$RDK_NETWORK_GROUP" ] || fail "RDK X5 network packagegroup must exist"
[ -f "$RDK_BPU_SMOKE" ] || fail "RDK X5 BPU smoke-test recipe must exist"
[ -f "$RDK_BPU_SMOKE_SOURCE" ] || fail "RDK X5 BPU smoke-test source must exist"
[ -f "$RDK_NETWORK_RECIPE" ] || fail "RDK X5 network profile recipe must exist"
[ -f "$RDK_NETWORK_PROFILE" ] || fail "RDK X5 Ethernet profile must exist"
grep -qxF 'COMPATIBLE_MACHINE = "^rdk-x5$"' "$RDK_BPU_SMOKE" ||
  fail "RDK X5 BPU smoke test must stay machine-scoped"
grep -qxF 'DEPENDS = "hobot-dnn"' "$RDK_BPU_SMOKE" ||
  fail "RDK X5 BPU smoke test must build against the DNN ABI"
grep -qxF 'RDEPENDS:${PN} = "hobot-dnn hobot-bpu-driver"' "$RDK_BPU_SMOKE" ||
  fail "RDK X5 BPU smoke test must require the DNN runtime and BPU driver"
grep -qxF '    https://archive.d-robotics.cc/downloads/rdk_model_zoo/rdk_x5/himloco/himloco_go2_bayese_1x270.bin;name=model;downloadfilename=himloco_go2_bayese_1x270.bin \' "$RDK_BPU_SMOKE" ||
  fail "RDK X5 BPU smoke test must fetch the official HIMLoco policy"
grep -qxF 'SRC_URI[model.sha256sum] = "7ce46ca2628f8bc236da0e8564180a1de92847bddf1ec00717ce7aa93e8c3e6a"' "$RDK_BPU_SMOKE" ||
  fail "RDK X5 BPU smoke test must pin the official HIMLoco checksum"
grep -qxF '    https://raw.githubusercontent.com/D-Robotics/rdk_model_zoo/7c1eb5393412df1f6d18a97f97c8c086e9ae4b94/samples/robotics/himloco/test_data/obs_history/000000.bin;name=input;downloadfilename=himloco_obs_history_000000.bin \' "$RDK_BPU_SMOKE" ||
  fail "RDK X5 BPU smoke test must fetch a pinned official HIMLoco observation"
grep -qxF 'SRC_URI[input.sha256sum] = "36ddc7317348df8e4ce21c3b0a6500bf411bbc47586703a0607d3120badda847"' "$RDK_BPU_SMOKE" ||
  fail "RDK X5 BPU smoke test must pin the official observation checksum"
grep -q 'hbDNNInfer' "$RDK_BPU_SMOKE_SOURCE" ||
  fail "RDK X5 BPU smoke test must submit a DNN inference"
grep -q 'hbDNNWaitTaskDone' "$RDK_BPU_SMOKE_SOURCE" ||
  fail "RDK X5 BPU smoke test must wait for DNN inference completion"
grep -qxF 'constexpr char kBpuModulePath[] = "/sys/module/bpu_hw_io_x5";' "$RDK_BPU_SMOKE_SOURCE" ||
  fail "RDK X5 BPU smoke test must verify the loaded BPU hardware-I/O module"
grep -qxF '      "output_fnv1a64=%016llx driver=bpu_hw_io_x5\n",' "$RDK_BPU_SMOKE_SOURCE" ||
  fail "RDK X5 BPU smoke test must terminate a PASS result with a newline"
grep -q 'algorithm=himloco-go2' "$RDK_BPU_SMOKE_SOURCE" ||
  fail "RDK X5 BPU smoke test must identify the HIMLoco algorithm"
grep -q 'std::isfinite' "$RDK_BPU_SMOKE_SOURCE" ||
  fail "RDK X5 BPU smoke test must reject non-finite HIMLoco tensors"
grep -qxF '    packagegroup-saha-base \' "$RDK_BASE_GROUP" ||
  fail "RDK X5 base image must compose the shared base packagegroup"
grep -qxF '    packagegroup-saha-rdk-x5-network \' "$RDK_BASE_GROUP" ||
  fail "RDK X5 base image must install its network policy packagegroup"
for rdk_network_package in \
  packagegroup-saha-network \
  saha-rdk-x5-network \
  systemd-networkd; do
  grep -qxF "    ${rdk_network_package} \\" "$RDK_NETWORK_GROUP" ||
    fail "RDK X5 network packagegroup is missing: $rdk_network_package"
done
[ -f "$RDK_NETWORKMANAGER_APPEND" ] || fail "RDK X5 NetworkManager bbappend must exist"
[ -f "$RDK_NETWORKMANAGER_POLICY" ] || fail "RDK X5 NetworkManager ownership policy must exist"
[ -f "$RDK_NETWORKMANAGER_ORDERING" ] || fail "RDK X5 NetworkManager ordering drop-in must exist"
[ -f "$RDK_HOBOT_WIFI_APPEND" ] || fail "RDK X5 hobot-wifi policy override must exist"
grep -qxF 'PACKAGECONFIG:append = " nmcli wifi"' "$RDK_NETWORKMANAGER_APPEND" ||
  fail "RDK X5 NetworkManager must explicitly build nmcli and Wi-Fi support"
grep -qxF 'REQUIRED_DISTRO_FEATURES:append = " systemd wifi"' "$RDK_NETWORKMANAGER_APPEND" ||
  fail "RDK X5 NetworkManager must enforce its distro feature contract"
grep -qxF 'SYSTEMD_AUTO_ENABLE:${PN}-daemon = "enable"' "$RDK_NETWORKMANAGER_APPEND" ||
  fail "RDK X5 NetworkManager daemon must be enabled"
grep -qxF 'unmanaged-devices=*,except:type:wifi' "$RDK_NETWORKMANAGER_POLICY" ||
  fail "RDK X5 NetworkManager must leave non-Wi-Fi interfaces to systemd-networkd"
grep -qxF 'Wants=hobot-wifi.service' "$RDK_NETWORKMANAGER_ORDERING" ||
  fail "RDK X5 NetworkManager must start the board Wi-Fi setup service"
grep -qxF 'After=hobot-wifi.service' "$RDK_NETWORKMANAGER_ORDERING" ||
  fail "RDK X5 NetworkManager must wait for board Wi-Fi setup"
grep -qxF 'PACKAGECONFIG:remove = "standalone-wifi"' "$RDK_HOBOT_WIFI_APPEND" ||
  fail "RDK X5 Saha images must disable the conflicting standalone Wi-Fi policy"
grep -q 'wifi' "$RDK_LAYER/conf/distro/saha-rdk-x5.conf" ||
  fail "saha-rdk-x5 distro must enable the Wi-Fi DISTRO_FEATURE"
grep -qxF 'COMPATIBLE_MACHINE = "^rdk-x5$"' "$RDK_NETWORK_RECIPE" ||
  fail "RDK X5 Ethernet profile must stay machine-scoped"
grep -qxF 'RDEPENDS:${PN} = "systemd-networkd"' "$RDK_NETWORK_RECIPE" ||
  fail "RDK X5 Ethernet profile must depend on systemd-networkd"
grep -qxF 'S = "${UNPACKDIR}"' "$RDK_NETWORK_RECIPE" ||
  fail "RDK X5 Ethernet profile must use Wrynose's unpack directory"
grep -qxF '    install -m 0644 ${UNPACKDIR}/20-saha-eth0.network \' "$RDK_NETWORK_RECIPE" ||
  fail "RDK X5 Ethernet profile must use systemd-networkd-safe permissions"
grep -qxF 'Name=eth0' "$RDK_NETWORK_PROFILE" ||
  fail "RDK X5 Ethernet profile must target eth0"
grep -qxF 'DHCP=yes' "$RDK_NETWORK_PROFILE" ||
  fail "RDK X5 Ethernet profile must use DHCP"
grep -qxF 'WKS_FILE = "rdk-x5.wks.in"' "$RDK_IMAGE" ||
  fail "RDK X5 image must select its WIC layout"
grep -qxF 'WKS_FILE_DEPENDS = "${WKS_FILE_DEPENDS_DEFAULT} d-robotics-bootfiles"' "$RDK_IMAGE" ||
  fail "RDK X5 image must preserve WIC tools and deploy boot assets before WIC"
grep -q 'packagegroup-saha-rdk-x5-ros2' "$RDK_IMAGE" ||
  fail "RDK X5 image must install its ROS 2 runtime packagegroup"
RDK_LTTNG_APPEND="$RDK_LAYER/recipes-kernel/lttng/lttng-tools_%.bbappend"
[ -f "$RDK_LTTNG_APPEND" ] || fail "RDK X5 must carry its LTTng compatibility override"
grep -qxF 'PTEST_ENABLED:pn-lttng-tools = "0"' "$RDK_LTTNG_APPEND" ||
  fail "RDK X5 must exclude only the incompatible LTTng ptest package"
grep -qxF 'bootloader --ptable msdos' "$RDK_WKS" ||
  fail "RDK X5 WIC layout must use the official MBR partition table"
grep -qxF 'part /config --source rawcopy --sourceparams="file=hobot-config.vfat" --fstype=vfat --label CONFIG --align 4096 --fixed-size 256M --use-label --fspassno=2' "$RDK_WKS" ||
  fail "RDK X5 WIC layout must identify CONFIG by label and check it before mounting"
grep -qxF 'part / --source rootfs --fstype=ext4 --label rootfs --align 4 --use-uuid' "$RDK_WKS" ||
  fail "RDK X5 WIC layout must place rootfs after CONFIG"
if rg -n -i '(^|[;[:space:]])(sf|nand|mtd|mmc)[[:space:]]+(erase|write)' "$RDK_WKS" "$RDK_IMAGE"; then
  fail "RDK X5 image metadata must not write persistent boot storage"
fi
if rg -n --fixed-strings '/home/' "$RDK_LAYER" "$RDK_REPOS" "$RDK_BASE" "$RDK_TARGET"; then
  fail "RDK X5 metadata must not reference a developer-local path"
fi

RDK_ROS_PACKAGEGROUP="$RDK_LAYER/recipes-saha/packagegroups/packagegroup-saha-rdk-x5-ros2.bb"
[ -f "$RDK_ROS_PACKAGEGROUP" ] || fail "RDK X5 ROS 2 packagegroup must exist"
grep -qxF 'RDEPENDS:${PN} = "packagegroup-saha-ros2"' "$RDK_ROS_PACKAGEGROUP" ||
  fail "RDK X5 ROS 2 packagegroup must reuse the shared ROS 2 packagegroup"

grep -A2 '^target:$' "$ROOT_DIR/kas/include/base.yml" |
  grep -qxF '  - saha-image-robot' ||
  fail "default kas build target must be saha-image-robot"

grep -q 'Build saha-image-robot' "$ROOT_DIR/scripts/saha-build" ||
  fail "saha-build help must describe the robot image target"

[ -f "$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-saha/images/saha-image-robot.bb" ] ||
  fail "saha-image-robot recipe must exist"
grep -q 'packagegroup-saha-ros2' "$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-saha/images/saha-image-robot.bb" ||
  fail "saha-image-robot must install the Saha ROS 2 packagegroup"

ROS2_PACKAGEGROUP="$COMMON_LAYER/recipes-saha/packagegroups/packagegroup-saha-ros2.bb"
[ -f "$ROS2_PACKAGEGROUP" ] ||
  fail "Saha ROS 2 packagegroup must exist"
grep -q 'ros-base' "$ROS2_PACKAGEGROUP" ||
  fail "Saha ROS 2 packagegroup must install ROS 2 ros-base"
grep -q 'ros2cli-common-extensions' "$ROS2_PACKAGEGROUP" ||
  fail "Saha ROS 2 packagegroup must install ROS 2 CLI extensions"
RMW_IMPLEMENTATION_APPEND="$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-ros/rmw-implementation/rmw-implementation_%.bbappend"
[ -f "$RMW_IMPLEMENTATION_APPEND" ] ||
  fail "Saha rmw-implementation bbappend must exist for Lyrical without meta-zenoh"
grep -q 'ROS_BUILD_DEPENDS:remove = "rmw-zenoh-cpp"' "$RMW_IMPLEMENTATION_APPEND" ||
  fail "Lyrical rmw-implementation must not require rmw-zenoh-cpp without meta-zenoh"
ROS_CORE_APPEND="$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-ros/variants/ros-core_%.bbappend"
[ -f "$ROS_CORE_APPEND" ] ||
  fail "Saha ros-core bbappend must exist for Lyrical without meta-zenoh"
grep -q "d.getVar('ROS_DISTRO') == 'lyrical'" "$ROS_CORE_APPEND" ||
  fail "ros-core launch-testing-ros removal must be limited to Lyrical"
grep -q "launch-testing-ros" "$ROS_CORE_APPEND" ||
  fail "Lyrical ros-core must not require skipped launch-testing-ros"
AMENT_CMAKE_ROS_APPEND="$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-ros/ament-cmake-ros/ament-cmake-ros_%.bbappend"
[ -f "$AMENT_CMAKE_ROS_APPEND" ] ||
  fail "Saha ament-cmake-ros bbappend must exist for Lyrical without meta-zenoh"
grep -q "d.getVar('ROS_DISTRO') == 'lyrical'" "$AMENT_CMAKE_ROS_APPEND" ||
  fail "ament-cmake-ros fixture removal must be limited to Lyrical"
grep -q "rmw-test-fixture-implementation" "$AMENT_CMAKE_ROS_APPEND" ||
  fail "Lyrical ament-cmake-ros must not require skipped rmw-test-fixture-implementation"

PROFILE_PACKAGEGROUP="$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-core/packagegroups/packagegroup-core-tools-profile.bbappend"
[ -f "$PROFILE_PACKAGEGROUP" ] ||
  fail "profiling packagegroup override must exist"
grep -qxF 'LTTNGTOOLS = "lttng-tools"' "$PROFILE_PACKAGEGROUP" ||
  fail "profiling tools must not pull unsupported lttng kernel module"
LTTNG_TOOLS_APPEND="$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-support/lttng/lttng-tools_%.bbappend"
[ -f "$LTTNG_TOOLS_APPEND" ] ||
  fail "lttng-tools bbappend must exist"
grep -qxF 'LTTNGMODULES = ""' "$LTTNG_TOOLS_APPEND" ||
  fail "lttng-tools ptest dependencies must not pull unsupported lttng kernel module"

for hostname_append in \
  "$COMMON_LAYER/recipes-core/base-files/base-files_%.bbappend"
do
  [ -f "$hostname_append" ] || fail "Saha base-files hostname override must exist: $hostname_append"
  grep -qxF 'hostname = "sahaWorld"' "$hostname_append" ||
    fail "Saha images must set the default device hostname to sahaWorld: $hostname_append"
done

USB_DEVICE_MODE_APPEND="$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-bsp/l4t-usb-device-mode/l4t-usb-device-mode.bbappend"
[ -f "$USB_DEVICE_MODE_APPEND" ] ||
  fail "l4t-usb-device-mode bbappend must exist"
grep -q 'multi-user.target.wants/usb-gadget.target' "$USB_DEVICE_MODE_APPEND" ||
  fail "USB gadget target must be wanted by multi-user.target for default USB network access"
grep -q 'saha-usb-role-device' "$USB_DEVICE_MODE_APPEND" ||
  fail "USB gadget setup must install the Saha USB role helper"
USB_ROLE_HELPER="$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-bsp/l4t-usb-device-mode/l4t-usb-device-mode/saha-usb-role-device"
[ -f "$USB_ROLE_HELPER" ] ||
  fail "Saha USB role helper must exist"
grep -q '/sys/class/usb_role/usb2-0-role-switch/role' "$USB_ROLE_HELPER" ||
  fail "Saha USB role helper must target the Orin USB2-0 role switch"
grep -q 'echo device >' "$USB_ROLE_HELPER" ||
  fail "Saha USB role helper must force device role before gadget start"

NETWORK_PACKAGEGROUP="$COMMON_LAYER/recipes-saha/packagegroups/packagegroup-saha-network.bb"
[ -f "$NETWORK_PACKAGEGROUP" ] ||
  fail "network packagegroup must exist"
grep -q 'networkmanager-nmcli' "$NETWORK_PACKAGEGROUP" ||
  fail "network packagegroup must install nmcli"
grep -q 'networkmanager-wifi' "$NETWORK_PACKAGEGROUP" ||
  fail "network packagegroup must install WiFi support"
NETWORKMANAGER_APPEND="$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-connectivity/networkmanager/networkmanager_%.bbappend"
[ -f "$NETWORKMANAGER_APPEND" ] ||
  fail "NetworkManager bbappend must exist"
grep -q 'except:type:wifi' "$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-connectivity/networkmanager/networkmanager/99-saha-unmanaged-devices.conf" ||
  fail "NetworkManager must leave USB gadget interfaces to systemd-networkd"
grep -q 'packagegroup-saha-network' "$COMMON_LAYER/recipes-saha/images/saha-image-common.inc" ||
  fail "default Saha images must include network packagegroup"
grep -q 'wifi' "$ROOT_DIR/saha-layers/meta-tegra-saha/conf/distro/tegra-saha.conf" ||
  fail "tegra-saha distro must enable wifi DISTRO_FEATURE"

grep -q 'gfortran' "$ROOT_DIR/docker/Dockerfile.yocto-builder" ||
  fail "Yocto builder image must include gfortran"

for removed_ros_path in \
  "$ROOT_DIR/kas/include/ros-jazzy.yml" \
  "$ROOT_DIR/kas/targets/orin-nx-16g-p3768-ros-jazzy.yml" \
  "$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-saha/images/saha-image-ros-jazzy-deps.bb" \
  "$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-saha/packagegroups/packagegroup-saha-ros-jazzy-deps.bb"; do
  [ ! -e "$removed_ros_path" ] || fail "ROS build path should be removed: $removed_ros_path"
done

if rg -n 'CORE_IMAGE_BASE_INSTALL \+= ".*(cuda-samples|nvidia-container-toolkit|packagegroup-saha-basetests)' \
  "$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-saha/images" >/tmp/saha-nonbasic-default-packages.out; then
  cat /tmp/saha-nonbasic-default-packages.out >&2
  fail "default base image must avoid samples and container toolkit extras"
fi

if rg -n 'DISTRO_FEATURES_DEFAULT( |"|})|TCLIBCAPPEND|S = "\$\{WORKDIR\}"|file://\$\{MACHINE\}/flashvars' \
  "$ROOT_DIR/saha-layers" >/tmp/saha-obsolete-wrynose-patterns.out; then
  cat /tmp/saha-obsolete-wrynose-patterns.out >&2
  fail "obsolete Wrynose-incompatible layer pattern found"
fi

if rg -n '\$\{WORKDIR\}/skip-dummy-interfaces.conf' \
  "$ROOT_DIR/saha-layers" >/tmp/saha-obsolete-workdir-source-paths.out; then
  cat /tmp/saha-obsolete-workdir-source-paths.out >&2
  fail "Wrynose unpacked source files must be read from UNPACKDIR"
fi

for legacy_path in \
  "$ROOT_DIR/resources" \
  "$ROOT_DIR/scripts/init.sh" \
  "$ROOT_DIR/scripts/clear.sh" \
  "$ROOT_DIR/scripts-setup" \
  "$ROOT_DIR/setup-env" \
  "$ROOT_DIR/dockers" \
  "$ROOT_DIR/saha-layers/meta-tegra-saha/.templateconf" \
  "$ROOT_DIR/saha-layers/meta-tegra-saha/conf/templates" \
  "$ROOT_DIR/saha-layers/meta-tegra-saha/conf/machine" \
  "$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-kernel" \
  "$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-bsp/tegra-binaries/tegra-bootfiles_%.bbappend" \
  "$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-bsp/tegra-binaries/tegra-saha-layout.bb" \
  "$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-bsp/tegra-binaries/tegra-saha-layout" \
  "$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-saha/data-overlay-setup" \
  "$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-saha/environment-setup" \
  "$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-saha/packagegroups/packagegroup-saha-env.bb" \
  "$ROOT_DIR/saha-layers/meta-tegra-saha/recipes-saha/packagegroups/packagegroup-saha-basetests.bb" \
  "$ROOT_DIR/saha-layers/meta-tegra-saha/scripts"; do
  [ ! -e "$legacy_path" ] || fail "legacy path should be removed: $legacy_path"
done

if rg -n 'rolling|apollo-nx|xavier-nx|tegra-rolling-kernel|tegra-saha-layout|data-overlay-setup|packagegroup-saha-env|packagegroup-saha-basetests|environment-setup|ros2_arm64|ros-jazzy|saha-image-ros|packagegroup-saha-ros-jazzy' \
  "$ROOT_DIR/kas" "$ROOT_DIR/saha-layers" "$ROOT_DIR/scripts" >/tmp/saha-legacy-references.out; then
  cat /tmp/saha-legacy-references.out >&2
  fail "legacy machine, ROS, or removed recipe reference found"
fi

shell_dry_run_output="$(SAHA_DRY_RUN=1 "$ROOT_DIR/scripts/saha-shell" agx-thor-devkit)"
contains "$shell_dry_run_output" "kas shell kas/targets/agx-thor-devkit.yml:kas/include/ros-distro-jazzy.yml:kas/include/homeassistant-container.yml"
contains "$shell_dry_run_output" " -it "

shell_command_dry_run_output="$(SAHA_DRY_RUN=1 "$ROOT_DIR/scripts/saha-shell" orin-nx-16g-p3768 -c "bitbake package-index")"
contains "$shell_command_dry_run_output" "kas shell kas/targets/orin-nx-16g-p3768.yml:kas/include/ros-distro-jazzy.yml:kas/include/homeassistant-container.yml -c bitbake\\ package-index"
if [[ "$shell_command_dry_run_output" == *" -it "* ]]; then
  fail "non-interactive shell command should not allocate a TTY"
fi

lyrical_shell_command_dry_run_output="$(SAHA_DRY_RUN=1 SAHA_ROS_DISTRO=lyrical "$ROOT_DIR/scripts/saha-shell" orin-nx-16g-p3768 -c "bitbake -p")"
contains "$lyrical_shell_command_dry_run_output" "kas shell kas/targets/orin-nx-16g-p3768.yml:kas/include/ros-distro-lyrical.yml:kas/include/homeassistant-container.yml -c bitbake\\ -p"

validate_dry_run_output="$(SAHA_DRY_RUN=1 "$ROOT_DIR/scripts/saha-validate" agx-orin-devkit)"
contains "$validate_dry_run_output" "kas dump --skip repo_setup_loop --skip finish_setup_repos --skip repos_checkout --skip repos_apply_patches kas/targets/agx-orin-devkit.yml:kas/include/ros-distro-jazzy.yml:kas/include/homeassistant-container.yml"

lyrical_validate_dry_run_output="$(SAHA_DRY_RUN=1 SAHA_ROS_DISTRO=lyrical "$ROOT_DIR/scripts/saha-validate" agx-orin-devkit)"
contains "$lyrical_validate_dry_run_output" "kas dump --skip repo_setup_loop --skip finish_setup_repos --skip repos_checkout --skip repos_apply_patches kas/targets/agx-orin-devkit.yml:kas/include/ros-distro-lyrical.yml:kas/include/homeassistant-container.yml"

rdk_validate_dry_run_output="$(
  SAHA_DRY_RUN=1 \
  SAHA_META_D_ROBOTICS_DIR=/tmp \
  "$ROOT_DIR/scripts/saha-validate" rdk-x5
)"
contains "$rdk_validate_dry_run_output" "kas dump --skip repo_setup_loop --skip finish_setup_repos --skip repos_checkout --skip repos_apply_patches kas/targets/rdk-x5.yml"

qcom_validate_dry_run_output="$(SAHA_DRY_RUN=1 "$ROOT_DIR/scripts/saha-validate" iq-9075-evk)"
contains "$qcom_validate_dry_run_output" "kas dump --skip repo_setup_loop --skip finish_setup_repos --skip repos_checkout --skip repos_apply_patches kas/targets/iq-9075-evk.yml:kas/include/homeassistant-container.yml"

bash "$ROOT_DIR/tests/test-flash-rdk-x5.sh"

echo "PASS: build framework contract"
