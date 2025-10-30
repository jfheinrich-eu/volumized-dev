#!/usr/bin/env bash
# Start the development container and pass GitHub token env vars for gh auto-auth.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

set -a
[ -f "${ROOT_DIR}/.env" ] && source "${ROOT_DIR}/.env"
set +a

IMAGE_NAME="${IMAGE_NAME:-volumized-dev:latest}"
CONTAINER_NAME="${CONTAINER_NAME:-proj-dev}"
VOLUME_NAME="${VOLUME_NAME:-proj-vol}"
PLATFORM="${PLATFORM:-linux/arm64}"
PORTS="${PORTS:-}"

PORT_ARGS=()
for p in ${PORTS}; do
  PORT_ARGS+=("-p" "${p}")
done

ENV_ARGS=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
  ENV_ARGS+=("-e" "GITHUB_TOKEN=${GITHUB_TOKEN}")
fi
if [ -n "${GH_TOKEN:-}" ]; then
  ENV_ARGS+=("-e" "GH_TOKEN=${GH_TOKEN}")
fi

if [ "${FORWARD_SSH_AGENT:-false}" = "true" ]; then
  if [ -n "${SSH_AUTH_SOCK:-}" ] && [ -S "${SSH_AUTH_SOCK}" ]; then
    ENV_ARGS+=("-v" "${SSH_AUTH_SOCK}:/ssh-agent")
    ENV_ARGS+=("-e" "SSH_AUTH_SOCK=/ssh-agent")
    echo "[i] Forwarding host SSH agent."
  else
    echo "[!] FORWARD_SSH_AGENT=true but SSH_AUTH_SOCK not available."
  fi
fi

echo "[i] Starting container '${CONTAINER_NAME}' ..."
docker run -d \
  --platform "${PLATFORM}" \
  --name "${CONTAINER_NAME}" \
  -v "${VOLUME_NAME}:/work" \
  "${PORT_ARGS[@]}" \
  "${ENV_ARGS[@]}" \
  "${IMAGE_NAME}"

echo "[✓] Container running: ${CONTAINER_NAME}"
echo "Open VS Code → Command Palette → 'Dev Containers: Attach to Running Container...' → ${CONTAINER_NAME} → open /work"
