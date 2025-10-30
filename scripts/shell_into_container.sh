#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-proj-dev}"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "[!] Container '${CONTAINER_NAME}' not running."
  exit 1
fi

echo "[i] Attaching interactive shell..."
docker exec -it "${CONTAINER_NAME}" zsh
