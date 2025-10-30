#!/usr/bin/env bash
# Purpose: Build the development image used by the volumized-dev environment.
# Notes:
#  - Idempotent; safe to re-run.
#  - Respects INSTALL_NODE / INSTALL_PYTHON build args.
#  - Uses Docker as provided by OrbStack on macOS (no Colima needed).
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
INSTALL_NODE="${INSTALL_NODE:-true}"
INSTALL_PYTHON="${INSTALL_PYTHON:-true}"

say "Building image: ${IMAGE_NAME}"
docker build \
  --build-arg INSTALL_NODE="${INSTALL_NODE}" \
  --build-arg INSTALL_PYTHON="${INSTALL_PYTHON}" \
  -t "${IMAGE_NAME}" \
  "${ROOT_DIR}"

say "Image built successfully: ${IMAGE_NAME}"
