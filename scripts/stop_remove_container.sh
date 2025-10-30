#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-proj-dev}"
echo "[i] Stopping container '${CONTAINER_NAME}' if running..."
docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
echo "[i] Removing container '${CONTAINER_NAME}' if exists..."
docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
echo "[✓] Container cleaned up."
