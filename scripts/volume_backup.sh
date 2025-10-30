#!/usr/bin/env bash
set -euo pipefail

VOLUME_NAME="${VOLUME_NAME:-proj-vol}"
BACKUP_FILE="${1:-${VOLUME_NAME}-backup-$(date +%Y%m%d-%H%M%S).tar.gz}"

# Use a throwaway container to tar the volume contents
echo "[i] Backing up volume '${VOLUME_NAME}' to '${BACKUP_FILE}'..."
docker run --rm \
  -v "${VOLUME_NAME}:/work:ro" \
  -v "$(pwd):/backup" \
  ubuntu:24.04 \
  bash -lc "cd /work && tar -czf /backup/$(basename "${BACKUP_FILE}") ."
echo "[✓] Backup created: ${BACKUP_FILE}"
