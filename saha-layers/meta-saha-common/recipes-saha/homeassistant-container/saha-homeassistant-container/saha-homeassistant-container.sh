#!/bin/sh
set -eu

ENV_FILE="/etc/default/homeassistant-container"
if [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC1090
    . "$ENV_FILE"
fi

SAHA_HOMEASSISTANT_CONFIG_DIR="${SAHA_HOMEASSISTANT_CONFIG_DIR:-/var/lib/homeassistant}"
SAHA_HOMEASSISTANT_IMAGE="${SAHA_HOMEASSISTANT_IMAGE:-ghcr.io/home-assistant/home-assistant:stable}"
SAHA_HOMEASSISTANT_IMAGE_TAR="${SAHA_HOMEASSISTANT_IMAGE_TAR:-/usr/share/saha/homeassistant/image.tar}"
SAHA_HOMEASSISTANT_CONTAINER_NAME="${SAHA_HOMEASSISTANT_CONTAINER_NAME:-homeassistant}"
SAHA_HOMEASSISTANT_TIMEZONE="${SAHA_HOMEASSISTANT_TIMEZONE:-UTC}"
SAHA_HOMEASSISTANT_PULL="${SAHA_HOMEASSISTANT_PULL:-0}"
SAHA_HOMEASSISTANT_DOCKER_WAIT="${SAHA_HOMEASSISTANT_DOCKER_WAIT:-60}"

log() {
    logger -t saha-homeassistant-container "$*"
}

image_loaded() {
    docker image inspect "$SAHA_HOMEASSISTANT_IMAGE" >/dev/null 2>&1
}

find_homeassistant_image() {
    docker images --format '{{.Repository}}:{{.Tag}}' \
        | grep 'home-assistant/home-assistant' \
        | grep -v ':<none>$' \
        | head -1
}

normalize_image_tag() {
    if image_loaded; then
        return 0
    fi

    loaded=$(find_homeassistant_image || true)
    if [ -n "$loaded" ] && [ "$loaded" != "$SAHA_HOMEASSISTANT_IMAGE" ]; then
        log "tagging ${loaded} as ${SAHA_HOMEASSISTANT_IMAGE}"
        docker tag "$loaded" "$SAHA_HOMEASSISTANT_IMAGE"
    fi
}

wait_for_docker() {
    waited=0
    while [ "$waited" -lt "$SAHA_HOMEASSISTANT_DOCKER_WAIT" ]; do
        if docker info >/dev/null 2>&1; then
            return 0
        fi
        sleep 2
        waited=$((waited + 2))
    done

    log "docker daemon not ready after ${SAHA_HOMEASSISTANT_DOCKER_WAIT}s"
    return 1
}

preload_image() {
    if image_loaded; then
        log "image already loaded: ${SAHA_HOMEASSISTANT_IMAGE}"
        return 0
    fi

    if [ ! -f "$SAHA_HOMEASSISTANT_IMAGE_TAR" ]; then
        log "preload tar missing: ${SAHA_HOMEASSISTANT_IMAGE_TAR}"
        return 0
    fi

    log "loading preload tar: ${SAHA_HOMEASSISTANT_IMAGE_TAR}"
    set +e
    load_output=$(docker load -i "$SAHA_HOMEASSISTANT_IMAGE_TAR" 2>&1)
    load_status=$?
    set -e

    if [ "$load_status" -ne 0 ]; then
        log "docker load failed: ${load_output}"
        return 1
    fi

    log "docker load succeeded: ${load_output}"

    if ! image_loaded; then
        loaded_ref=$(printf '%s\n' "$load_output" | sed -n 's/^Loaded image: //p' | tail -1)
        if [ -n "$loaded_ref" ]; then
            log "tagging loaded image ${loaded_ref} as ${SAHA_HOMEASSISTANT_IMAGE}"
            docker tag "$loaded_ref" "$SAHA_HOMEASSISTANT_IMAGE"
        fi
    fi

    normalize_image_tag
}

ensure_image() {
    wait_for_docker
    preload_image
    normalize_image_tag

    if image_loaded; then
        return 0
    fi

    if [ "$SAHA_HOMEASSISTANT_PULL" = "1" ]; then
        log "pulling remote image: ${SAHA_HOMEASSISTANT_IMAGE}"
        docker pull "$SAHA_HOMEASSISTANT_IMAGE"
        return 0
    fi

    log "image missing and remote pull disabled (SAHA_HOMEASSISTANT_PULL=0)"
    return 1
}

start_container() {
    mkdir -p "$SAHA_HOMEASSISTANT_CONFIG_DIR"
    ensure_image

    if docker inspect "$SAHA_HOMEASSISTANT_CONTAINER_NAME" >/dev/null 2>&1; then
        log "starting existing container: ${SAHA_HOMEASSISTANT_CONTAINER_NAME}"
        docker start "$SAHA_HOMEASSISTANT_CONTAINER_NAME"
        return 0
    fi

    log "creating container ${SAHA_HOMEASSISTANT_CONTAINER_NAME} from ${SAHA_HOMEASSISTANT_IMAGE}"
    docker run -d \
        --name "$SAHA_HOMEASSISTANT_CONTAINER_NAME" \
        --restart unless-stopped \
        --privileged \
        --network host \
        -e "TZ=${SAHA_HOMEASSISTANT_TIMEZONE}" \
        -v "${SAHA_HOMEASSISTANT_CONFIG_DIR}:/config" \
        "$SAHA_HOMEASSISTANT_IMAGE"
}

stop_container() {
    if docker inspect "$SAHA_HOMEASSISTANT_CONTAINER_NAME" >/dev/null 2>&1; then
        log "stopping container: ${SAHA_HOMEASSISTANT_CONTAINER_NAME}"
        docker stop "$SAHA_HOMEASSISTANT_CONTAINER_NAME" >/dev/null 2>&1 || true
    fi
}

case "${1:-}" in
    wait-docker)
        wait_for_docker
        ;;
    start)
        start_container
        ;;
    stop)
        stop_container
        ;;
    restart)
        stop_container
        start_container
        ;;
    *)
        echo "Usage: $0 {wait-docker|start|stop|restart}" >&2
        exit 2
        ;;
esac
