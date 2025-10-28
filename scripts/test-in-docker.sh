#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME=${IMAGE_NAME:-transloadit-ruby-sdk-dev}
CACHE_DIR=.docker-cache

ensure_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is required to run this script." >&2
    exit 1
  fi

  if ! docker info >/dev/null 2>&1; then
    if [[ -z "${DOCKER_HOST:-}" && -S "$HOME/.colima/default/docker.sock" ]]; then
      export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
    fi
  fi

  if ! docker info >/dev/null 2>&1; then
    echo "Docker daemon is not reachable. Start Docker (or Colima) and retry." >&2
    exit 1
  fi
}

configure_platform() {
  if [[ -z "${DOCKER_PLATFORM:-}" ]]; then
    local arch
    arch=$(uname -m)
    if [[ "$arch" == "arm64" || "$arch" == "aarch64" ]]; then
      DOCKER_PLATFORM=linux/amd64
    fi
  fi
}

ensure_docker
configure_platform

if [[ $# -eq 0 ]]; then
  RUN_CMD='set -e; bundle install --jobs 4 --retry 3; bundle exec rake test'
else
  printf -v USER_CMD '%q ' "$@"
  RUN_CMD="set -e; bundle install --jobs 4 --retry 3; ${USER_CMD}"
fi

mkdir -p "$CACHE_DIR/bundle" "$CACHE_DIR/npm-cache"

BUILD_ARGS=()
if [[ -n "${DOCKER_PLATFORM:-}" ]]; then
  BUILD_ARGS+=(--platform "$DOCKER_PLATFORM")
fi
BUILD_ARGS+=(-t "$IMAGE_NAME" -f Dockerfile .)

docker build "${BUILD_ARGS[@]}"

DOCKER_ARGS=(
  --rm
  --user "$(id -u):$(id -g)"
  -e HOME=/workspace
  -e BUNDLE_PATH=/workspace/$CACHE_DIR/bundle
  -e BUNDLE_APP_CONFIG=/workspace/$CACHE_DIR/bundle-config
  -e BUNDLE_CACHE_PATH=/workspace/$CACHE_DIR/bundle-cache
  -e npm_config_cache=/workspace/$CACHE_DIR/npm-cache
  -e TEST_NODE_PARITY="${TEST_NODE_PARITY:-0}"
  -v "$PWD":/workspace
  -w /workspace
)

if [[ -n "${DOCKER_PLATFORM:-}" ]]; then
  DOCKER_ARGS+=(--platform "$DOCKER_PLATFORM")
fi

if [[ -f .env ]]; then
  DOCKER_ARGS+=(--env-file "$PWD/.env")
fi

PASSTHROUGH_ENV_VARS=(
  TRANSLOADIT_KEY
  TRANSLOADIT_SECRET
  TRANSLOADIT_HOST
  TRANSLOADIT_REGION
  TRANSLOADIT_TEMPLATE_ID
  RUBY_SDK_E2E
)

for var in "${PASSTHROUGH_ENV_VARS[@]}"; do
  if [[ -n "${!var:-}" ]]; then
    DOCKER_ARGS+=(-e "$var=${!var}")
  fi
done

exec docker run "${DOCKER_ARGS[@]}" "$IMAGE_NAME" bash -lc "$RUN_CMD"
