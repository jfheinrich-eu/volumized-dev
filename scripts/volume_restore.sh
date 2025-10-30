#!/usr/bin/env bash
set -euo pipefail

VOLUME_NAME="${VOLUME_NAME:-proj-vol}"
BACKUP_FILE="${1:-}"
if [ -z "${BACKUP_FILE}" ]; then
  echo "Usage: $0 <backup.tar.gz>"
  exit 1
fi

echo "[i] Restoring '${BACKUP_FILE}' into volume '${VOLUME_NAME}'..."
docker run --rm \
  -v "${VOLUME_NAME}:/work" \
  -v "$(pwd):/backup:ro" \
  ubuntu:24.04 \
  bash -lc "cd /work && tar -xzf /backup/$(basename "${BACKUP_FILE}")"
echo "[✓] Restore complete."
