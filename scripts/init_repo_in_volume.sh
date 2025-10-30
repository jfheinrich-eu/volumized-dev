#!/usr/bin/env bash
# Purpose: Initialize a Git repository inside the Docker volume at /work.
# Behavior:
#  - If a repo already exists in the volume, it will be left intact.
#  - If GIT_CLONE_URL is provided, clone into /work (shallow by default).
#  - Otherwise, create an empty repo with an initial commit on 'main'.
#  - Ensures /work/.devcontainer/devcontainer.json exists; if not, copies from host (if present).
#  - All comments are in English as requested.

set -euo pipefail

say()  { printf "[i] %s\n" "$*"; }
warn() { printf "[!] %s\n" "$*" >&2; }
die()  { printf "[x] %s\n" "$*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

# Load .env if available
set -a
[ -f ".env" ] && source ".env"
set +a

IMAGE_NAME="${IMAGE_NAME:-volumized-dev:latest}"
VOLUME_NAME="${VOLUME_NAME:-proj-vol}"
PLATFORM="${PLATFORM:-linux/arm64}"
GIT_CLONE_URL="${GIT_CLONE_URL:-}"
GIT_DEFAULT_BRANCH="${GIT_DEFAULT_BRANCH:-main}"

# Helper: copy a local devcontainer.json into the volume if missing
copy_devcontainer_if_missing() {
  local devjson_host="${ROOT_DIR}/.devcontainer/devcontainer.json"
  if [ ! -f "${devjson_host}" ]; then
    # Also support flat file at project root (legacy)
    devjson_host="${ROOT_DIR}/devcontainer.json"
  fi

  # Ensure directory in volume and copy if host file exists
  docker run --rm \
    --platform "${PLATFORM}" \
    -v "${VOLUME_NAME}:/work" \
    ubuntu:24.04 \
    bash -lc 'install -d -m 0755 /work/.devcontainer'

  if [ -f "${devjson_host}" ]; then
    say "Copying devcontainer.json from host into volume..."
    docker run --rm \
      --platform "${PLATFORM}" \
      -v "${VOLUME_NAME}:/work" \
      -v "${ROOT_DIR}:/host:ro" \
      ubuntu:24.04 \
      bash -lc 'cp /host/'"$(realpath --relative-to="${ROOT_DIR}" "${devjson_host}")"' /work/.devcontainer/devcontainer.json && chmod 0644 /work/.devcontainer/devcontainer.json'
  else
    warn "No devcontainer.json found on host — you may want to add one later."
  fi
}

# Check if volume already contains a repo
HAS_GIT=$(docker run --rm \
  -v "${VOLUME_NAME}:/check" \
  ubuntu:24.04 bash -lc 'test -d /check/.git && echo yes || echo no')

if [ "${HAS_GIT}" = "yes" ]; then
  say "Repository already present in volume '${VOLUME_NAME}'. Skipping initialization."
  copy_devcontainer_if_missing
  exit 0
fi

# Initialize inside the volume using the development image (so git is available)
if [ -n "${GIT_CLONE_URL}" ]; then
  say "Cloning repository into volume '${VOLUME_NAME}' ..."
  docker run --rm -it \
    --platform "${PLATFORM}" \
    -v "${VOLUME_NAME}:/work" \
    "${IMAGE_NAME}" \
    zsh -lc 'set -e; cd /work; git clone --depth 1 "'"${GIT_CLONE_URL}"'" . || (echo "[!] Shallow clone failed, trying full clone..." && git clone "'"${GIT_CLONE_URL}"'" .)'
else
  say "Initializing empty repository in volume '${VOLUME_NAME}' on branch '${GIT_DEFAULT_BRANCH}' ..."
  docker run --rm -it \
    --platform "${PLATFORM}" \
    -v "${VOLUME_NAME}:/work" \
    "${IMAGE_NAME}" \
    zsh -lc 'set -e; cd /work; git init -b "'"${GIT_DEFAULT_BRANCH}"'" .; git commit --allow-empty -m "chore: initial empty commit"'
fi

copy_devcontainer_if_missing
say "Repository initialization completed."
