#!/usr/bin/env bash
# Purpose: Orchestrate the full setup (image build, volume init, secrets import, container run)
# Environment: macOS with OrbStack (Docker backend) + VS Code Dev Containers
# Notes:
#  - Idempotent: safe to re-run; it will not destroy your Docker volume.
#  - Uses OrbStack (no Colima). Will attempt to start OrbStack's Docker if docker is unavailable.
#  - Uses new secrets path: writes secrets into /work/.secrets_home via put_secrets_into_volume.sh
#  - run_container.sh forwards GITHUB_TOKEN/GH_TOKEN for gh auto-auth inside the container.
#  - All comments in English as requested.

set -euo pipefail

say()  { printf "[i] %s\n" "$*"; }
warn() { printf "[!] %s\n" "$*" >&2; }
die()  { printf "[x] %s\n" "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command '$1' not found in PATH."
}

project_root() {
  # Determine project root by presence of Dockerfile and .env.example
  local here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "${here}/Dockerfile" ] && [ -f "${here}/.env.example" ]; then
    echo "${here}"
    return
  fi
  if [ -f "${here}/../Dockerfile" ] && [ -f "${here}/../.env.example" ]; then
    echo "${here}/.."
    return
  fi
  echo "${here}"
}

ROOT_DIR="$(project_root)"
cd "${ROOT_DIR}"

say "Project root: ${ROOT_DIR}"

# --- Pre-flight --------------------------------------------------------------

require_cmd docker

# Prefer OrbStack. If docker engine not responsive, try to start OrbStack.
if ! docker version >/dev/null 2>&1; then
  if command -v orb >/dev/null 2>&1; then
    warn "Docker engine not responding. Attempting to start OrbStack Docker..."
    if ! orb start docker >/dev/null 2>&1; then
      die "Failed to start OrbStack Docker service."
    fi
    # Re-check
    docker version >/dev/null 2>&1 || die "Docker still not responding after starting OrbStack."
  else
    die "OrbStack CLI ('orb') not found and Docker is unavailable."
  fi
fi

# Ensure .env exists
if [ ! -f .env ]; then
  warn ".env not found. Copying from .env.example..."
  cp -n .env.example .env || die "Failed to create .env from .env.example"
  warn "Review '.env' values before continuing (image/volume/container names, tokens, key paths, etc.)."
fi

# Load env
# shellcheck disable=SC1091
set -a; source .env; set +a

IMAGE_NAME="${IMAGE_NAME:-volumized-dev:latest}"
CONTAINER_NAME="${CONTAINER_NAME:-proj-dev}"
VOLUME_NAME="${VOLUME_NAME:-proj-vol}"
PLATFORM="${PLATFORM:-linux/arm64}"
FORWARD_SSH_AGENT="${FORWARD_SSH_AGENT:-false}"

SCRIPTS_DIR="${ROOT_DIR}/scripts"
[ -d "${SCRIPTS_DIR}" ] || die "Missing scripts/ directory."

for s in build_image.sh create_volume.sh init_repo_in_volume.sh put_secrets_into_volume.sh run_container.sh stop_remove_container.sh; do
  [ -x "${SCRIPTS_DIR}/${s}" ] || die "Script not executable or missing: scripts/${s}"
done

# --- Build image -------------------------------------------------------------

FORCE="${1:-}"
if ! docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1 || [ "${FORCE}" = "--rebuild" ]; then
  say "Building image: ${IMAGE_NAME} ..."
  bash "${SCRIPTS_DIR}/build_image.sh"
else
  say "Image already present: ${IMAGE_NAME} (use --rebuild to force)."
fi

# --- Create volume -----------------------------------------------------------

if docker volume inspect "${VOLUME_NAME}" >/dev/null 2>&1; then
  say "Volume exists: ${VOLUME_NAME}"
else
  say "Creating volume: ${VOLUME_NAME}"
  bash "${SCRIPTS_DIR}/create_volume.sh"
fi

# --- Initialize repo inside the volume --------------------------------------

say "Checking if repository is already initialized in the volume..."
HAS_GIT=$(docker run --rm -v "${VOLUME_NAME}:/check" ubuntu:24.04 bash -lc 'test -d /check/.git && echo yes || echo no')
if [ "${HAS_GIT}" = "yes" ]; then
  say "Repository detected in volume ${VOLUME_NAME}. Skipping init."
else
  say "Initializing repository in volume ${VOLUME_NAME}..."
  bash "${SCRIPTS_DIR}/init_repo_in_volume.sh"
fi

# --- Place secrets into /work/.secrets_home ---------------------------------

say "Placing SSH/GPG secrets into the volume under /work/.secrets_home ..."
bash "${SCRIPTS_DIR}/put_secrets_into_volume.sh" || die "Failed to place secrets into volume."

# --- Start or restart container ---------------------------------------------

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  RUNNING=$(docker inspect -f '{{.State.Running}}' "${CONTAINER_NAME}" || echo "false")
  if [ "${RUNNING}" != "true" ]; then
    warn "Container ${CONTAINER_NAME} exists but is not running. Removing it..."
    bash "${SCRIPTS_DIR}/stop_remove_container.sh" || true
  else
    say "Container ${CONTAINER_NAME} is already running."
  fi
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  say "Starting container: ${CONTAINER_NAME}"
  bash "${SCRIPTS_DIR}/run_container.sh"
fi

# --- Install test script into the volume (if not present) -------------------

TEST_PATH_LOCAL="$(mktemp -d)/test_dev_env.sh"
cat > "${TEST_PATH_LOCAL}" <<'EOS'
#!/usr/bin/env bash
# Container self-test: SSH to GitHub, GPG signing, basic toolchain
set -euo pipefail
say(){ printf "[i] %s\n" "$*"; }
die(){ printf "[x] %s\n" "$*" >&2; exit 1; }
require_cmd(){ command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

say "Running container environment self-test..."

for c in git gpg ssh; do require_cmd "$c"; done
say "git/gpg/ssh present."

set +e
ssh -T -o StrictHostKeyChecking=accept-new git@github.com
SSH_STATUS=$?
set -e
if [ "${SSH_STATUS}" -eq 1 ] || [ "${SSH_STATUS}" -eq 255 ]; then
  say "SSH to github.com reachable (exit=${SSH_STATUS})."
else
  say "Warning: unusual SSH exit=${SSH_STATUS}. Continuing."
fi

if ! gpg --list-secret-keys --keyid-format LONG >/dev/null 2>&1; then
  die "No GPG secret keys detected. Import keys and re-run."
fi

KEYID="$(gpg --list-secret-keys --keyid-format LONG | awk "/^sec/ {print \$2}" | sed -E "s|[^/]+/||" | head -n1)"
[ -n "${KEYID}" ] || die "Failed to extract a GPG key ID."

GIT_NAME="$(git config --global user.name || true)"
GIT_MAIL="$(git config --global user.email || true)"
git config --global gpg.program gpg
git config --global commit.gpgsign true
git config --global user.signingkey "${KEYID}"

TMPDIR="$(mktemp -d /tmp/devtest.XXXXXX)"
trap 'rm -rf "${TMPDIR}"' EXIT
cd "${TMPDIR}"
git init -q .
git config user.name  "${GIT_NAME:-Test User}"
git config user.email "${GIT_MAIL:-test@example.com}"
date -u +"%FT%TZ" > probe.txt
git add probe.txt
set +e
git commit -S -m "chore: signed commit probe"
RC=$?
set -e
[ "${RC}" -eq 0 ] || die "Signed commit failed (rc=${RC})."

say "Signed commit succeeded."
git log --show-signature -1
if command -v node >/dev/null 2>&1; then say "Node: $(node -v)"; fi
if command -v python3 >/dev/null 2>&1; then say "Python: $(python3 --version)"; fi
say "All checks passed."
EOS
chmod +x "${TEST_PATH_LOCAL}"

# Place into volume path
docker run --rm \
  -v "${VOLUME_NAME}:/work" \
  -v "$(dirname "${TEST_PATH_LOCAL}"):/hosttmp:ro" \
  ubuntu:24.04 \
  bash -lc 'install -d -m 0755 /work/.devcontainer && cp /hosttmp/$(basename '"${TEST_PATH_LOCAL}"') /work/.devcontainer/test_dev_env.sh && chmod +x /work/.devcontainer/test_dev_env.sh'

rm -f "${TEST_PATH_LOCAL}"
say "Test script installed at /work/.devcontainer/test_dev_env.sh"

cat <<TIP

Next steps:
  1) Open VS Code
  2) Command Palette → "Dev Containers: Attach to Running Container..."
  3) Select "${CONTAINER_NAME}"
  4) Open folder "/work"
  5) Inside the container terminal, run:
       /work/.devcontainer/test_dev_env.sh

Notes:
  - If you set GITHUB_TOKEN or GH_TOKEN in .env, gh will auto-authenticate.
  - Secrets are stored in the volume under /work/.secrets_home and mirrored to /home/vscode on shell start.
  - Re-run this script anytime; it won't wipe your Docker volume.
TIP
