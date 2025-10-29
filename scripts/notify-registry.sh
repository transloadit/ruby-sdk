#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME=${IMAGE_NAME:-transloadit-ruby-sdk-dev}

err() {
  echo "notify-registry: $*" >&2
}

if ! command -v docker >/dev/null 2>&1; then
  err "Docker is required to publish the gem."
  exit 1
fi

if [[ -z "${GEM_HOST_API_KEY:-}" ]]; then
  err "GEM_HOST_API_KEY environment variable is not set. Generate a RubyGems API key with push permissions and export it before running this script."
  exit 1
fi

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  err "Docker image '$IMAGE_NAME' not found. Building it now..."
  docker build -t "$IMAGE_NAME" -f Dockerfile .
fi

version=$(
  docker run --rm \
    -v "$PWD":/workspace \
    -w /workspace \
    "$IMAGE_NAME" \
    ruby -Ilib -e 'require "transloadit/version"; puts Transloadit::VERSION'
)

gem_file="transloadit-${version}.gem"

err "Building ${gem_file}..."
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e HOME=/workspace \
  -v "$PWD":/workspace \
  -w /workspace \
  "$IMAGE_NAME" \
  bash -lc "set -euo pipefail; rm -f ${gem_file}; gem build transloadit.gemspec >/dev/null"

err "Pushing ${gem_file} to RubyGems..."
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e HOME=/workspace \
  -e GEM_HOST_API_KEY="$GEM_HOST_API_KEY" \
  -v "$PWD":/workspace \
  -w /workspace \
  "$IMAGE_NAME" \
  bash -lc "set -euo pipefail; gem push ${gem_file}"

err "Removing local ${gem_file}..."
rm -f "${gem_file}"

echo "notify-registry: Successfully pushed ${gem_file} to RubyGems."
