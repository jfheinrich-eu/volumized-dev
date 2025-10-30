#!/usr/bin/env bash
# Copy SSH/GPG secrets into the project volume at /work/.secrets_home
# They will be mirrored into /home/vscode by the container's gh-auto-auth hook.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

set -a
[ -f "${ROOT_DIR}/.env" ] && source "${ROOT_DIR}/.env"
set +a

IMAGE_NAME="${IMAGE_NAME:-volumized-dev:latest}"
VOLUME_NAME="${VOLUME_NAME:-proj-vol}"
PLATFORM="${PLATFORM:-linux/arm64}"

SSH_PRIVATE_KEY_PATH="${SSH_PRIVATE_KEY_PATH:-}"
SSH_PUBLIC_KEY_PATH="${SSH_PUBLIC_KEY_PATH:-}"
SSH_CONFIG_PATH="${SSH_CONFIG_PATH:-}"
GPG_PRIVATE_KEY_PATH="${GPG_PRIVATE_KEY_PATH:-}"
GPG_PUBLIC_KEY_PATH="${GPG_PUBLIC_KEY_PATH:-}"
GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"
GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"
GIT_GPG_SIGNING_KEY="${GIT_GPG_SIGNING_KEY:-}"

say(){ printf "[i] %s\n" "$*"; }
die(){ printf "[x] %s\n" "$*" >&2; exit 1; }

check_file(){ [ -z "$1" ] || [ -f "$1" ] || die "File not found: $1"; }

check_file "$SSH_PRIVATE_KEY_PATH"
check_file "$SSH_PUBLIC_KEY_PATH"
check_file "$SSH_CONFIG_PATH"
check_file "$GPG_PRIVATE_KEY_PATH"
check_file "$GPG_PUBLIC_KEY_PATH"

HOST_HOME="$(eval echo ~)"

say "Writing secrets into volume '${VOLUME_NAME}' under /work/.secrets_home ..."

docker run --rm -i \
  --platform "${PLATFORM}" \
  -v "${VOLUME_NAME}:/work" \
  -v "${HOST_HOME}:${HOST_HOME}:ro" \
  "${IMAGE_NAME}" \
  bash -lc '
set -e
install -d -m 0755 -o 1000 -g 1000 /work/.secrets_home
install -d -m 0700 -o 1000 -g 1000 /work/.secrets_home/.ssh
install -d -m 0700 -o 1000 -g 1000 /work/.secrets_home/.gnupg

# SSH
if [ -n "'"${SSH_PRIVATE_KEY_PATH}"'" ]; then
  cp "'"${SSH_PRIVATE_KEY_PATH}"'" /work/.secrets_home/.ssh/id_key
  chown 1000:1000 /work/.secrets_home/.ssh/id_key
  chmod 600 /work/.secrets_home/.ssh/id_key
fi
if [ -n "'"${SSH_PUBLIC_KEY_PATH}"'" ]; then
  cp "'"${SSH_PUBLIC_KEY_PATH}"'" /work/.secrets_home/.ssh/id_key.pub
  chown 1000:1000 /work/.secrets_home/.ssh/id_key.pub
  chmod 644 /work/.secrets_home/.ssh/id_key.pub
fi

# SSH config
if [ -n "'"${SSH_CONFIG_PATH}"'" ]; then
  cp "'"${SSH_CONFIG_PATH}"'" /work/.secrets_home/.ssh/config
else
  cat >/work/.secrets_home/.ssh/config <<EOF
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_key
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
EOF
fi
chown 1000:1000 /work/.secrets_home/.ssh/config
chmod 600 /work/.secrets_home/.ssh/config

# known_hosts
ssh-keyscan -t rsa,ecdsa,ed25519 github.com >> /work/.secrets_home/.ssh/known_hosts || true
chown 1000:1000 /work/.secrets_home/.ssh/known_hosts
chmod 644 /work/.secrets_home/.ssh/known_hosts

# GPG
if [ -n "'"${GPG_PRIVATE_KEY_PATH}"'" ]; then
  if ! command -v gpg >/dev/null 2>&1; then echo "gpg not found in image"; exit 1; fi
  install -d -m 0700 -o 1000 -g 1000 /tmp/gnupg
  export GNUPGHOME=/tmp/gnupg
  if [ -f "'"${GPG_PRIVATE_KEY_PATH}.gpg"'" ]; then
    gpg --output "'"${GPG_PRIVATE_KEY_PATH}"'" --decrypt "'"${GPG_PRIVATE_KEY_PATH}.gpg"'"
  fi
  if [ -n "'"${GPG_PASSPHRASE}"'" ]; then
    gpg --batch --yes --pinentry-mode loopback --passphrase "'"${GPG_PASSPHRASE}"'" --import "'"${GPG_PRIVATE_KEY_PATH}"'"
  else
    gpg --batch --yes --import "'"${GPG_PRIVATE_KEY_PATH}"'"
  fi
  if [ -n "'"${GPG_PUBLIC_KEY_PATH}"'" ]; then
    gpg --batch --yes --import "'"${GPG_PUBLIC_KEY_PATH}"'"
  fi
  if [ -f "'"${GPG_PRIVATE_KEY_PATH}.gpg"'" ]; then
    rm "'"${GPG_PRIVATE_KEY_PATH}.gpg"'"
  fi
  gpg --list-keys --with-colons | awk -F: "/^pub/ {print \$5\":6:\"}" | gpg --import-ownertrust || true
  rm -rf /work/.secrets_home/.gnupg
  mv /tmp/gnupg /work/.secrets_home/.gnupg
  chown -R 1000:1000 /work/.secrets_home/.gnupg
  chmod 700 /work/.secrets_home/.gnupg
  find /work/.secrets_home/.gnupg -type f -exec chmod 600 {} \; || true
  find /work/.secrets_home/.gnupg -type d -exec chmod 700 {} \; || true
fi

# Write a template gitconfig (optional)
cat >/work/.secrets_home/.gitconfig.template <<GITCFG
[user]
    name = '"${GIT_USER_NAME}"'
    email = '"${GIT_USER_EMAIL}"'
[commit]
    gpgsign = true
[gpg]
    program = gpg
[user]
    signingkey = '"${GIT_GPG_SIGNING_KEY}"'
GITCFG
chown 1000:1000 /work/.secrets_home/.gitconfig.template
chmod 600 /work/.secrets_home/.gitconfig.template
'

say "Done. Secrets stored under /work/.secrets_home and will sync on container start."
