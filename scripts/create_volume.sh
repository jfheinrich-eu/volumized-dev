#!/usr/bin/env bash
set -euo pipefail

VOLUME_NAME="${VOLUME_NAME:-proj-vol}"
echo "[i] Creating volume '${VOLUME_NAME}' if not exists..."
docker volume create "${VOLUME_NAME}" >/dev/null
echo "[✓] Volume ready: ${VOLUME_NAME}"
