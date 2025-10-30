# syntax=docker/dockerfile:1.7
# Volumized Dev Environment - Dockerfile (with GitHub CLI auto-auth)
FROM ubuntu:24.04

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

ARG INSTALL_NODE=true
ARG NODE_VERSION="lts/*"
ARG INSTALL_PYTHON=true

ENV DEBIAN_FRONTEND=noninteractive

# Base packages
RUN apt-get update && apt-get install -y \
    ca-certificates curl git zsh sudo \
    build-essential pkg-config \
    bash-completion locales less vim \
    wget unzip gnupg lsb-release \
    openssh-client \
    iproute2 iputils-ping net-tools telnet dnsutils \
 && rm -rf /var/lib/apt/lists/*

# Locale
RUN sed -i 's/# en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen \
 && apt-get update && apt-get install -y locales \
 && locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Non-root user
RUN groupadd --gid ${USER_GID} ${USERNAME} \
 && useradd -s /bin/zsh --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Workspace
RUN mkdir -p /work && chown ${USERNAME}:${USERNAME} /work
WORKDIR /work

# Optional Node via nvm
ENV NVM_DIR=/usr/local/share/nvm
RUN if [ "${INSTALL_NODE}" = "true" ]; then \
      mkdir -p $NVM_DIR && curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
      && bash -lc ". $NVM_DIR/nvm.sh && nvm install ${NODE_VERSION} && nvm alias default ${NODE_VERSION}"; \
    fi
ENV PATH=$NVM_DIR/versions/node/$(bash -lc "if [ -s $NVM_DIR/nvm.sh ]; then . $NVM_DIR/nvm.sh; nvm version default; fi")/bin:$PATH

# Optional Python (system python3 + pip)
RUN if [ "${INSTALL_PYTHON}" = "true" ]; then \
      apt-get update && apt-get install -y python3 python3-pip python3-venv \
      && rm -rf /var/lib/apt/lists/*; \
    fi

# Git defaults
RUN git config --system init.defaultBranch main

# Install GitHub CLI (official apt repo)
RUN type -p curl >/dev/null || (apt-get update && apt-get install -y curl ca-certificates gnupg) \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
 && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y gh \
 && rm -rf /var/lib/apt/lists/*

# gh auto-auth helper (root installs into /usr/local/bin)
USER root
RUN printf '%s\n' '#!/usr/bin/env bash' \
 'set -euo pipefail' \
 'echo "[gh-auto-auth] Syncing secrets from /work/.secrets_home (if present) ..."' \
 'if [ -d /work/.secrets_home ]; then' \
 '  rsync -a --delete --chown=vscode:vscode --chmod=Du=rwx,Dg=rx,Do= --exclude="*.bak" /work/.secrets_home/ /home/vscode/ || true' \
 'fi' \
 'install -d -m 0700 -o vscode -g vscode /home/vscode/.ssh || true' \
 'install -d -m 0700 -o vscode -g vscode /home/vscode/.gnupg || true' \
 'install -d -m 0700 -o vscode -g vscode /home/vscode/.config/gh || true' \
 'TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"' \
 'if [ -n "$TOKEN" ]; then' \
 '  echo "[gh-auto-auth] Authenticating gh with token ..."' \
 '  sudo -u vscode bash -lc "printf %s \"$TOKEN\" | gh auth login --hostname github.com --with-token >/dev/null 2>&1 || true"' \
 '  sudo -u vscode gh config set git_protocol ssh || true' \
 '  sudo -u vscode gh auth status || true' \
 'else' \
 '  echo "[gh-auto-auth] No token provided. Configuring SSH-only git ..."' \
 '  sudo -u vscode gh config set git_protocol ssh || true' \
 '  if [ -f /home/vscode/.ssh/id_key ]; then eval "$(ssh-agent -s)" >/dev/null 2>&1 || true; ssh-add /home/vscode/.ssh/id_key >/dev/null 2>&1 || true; fi' \
 '  sudo -u vscode gh auth setup-git || true' \
 'fi' \
 > /usr/local/bin/gh-auto-auth.sh \
 && chmod +x /usr/local/bin/gh-auto-auth.sh

# Minimal zsh setup and auto-call of gh-auto-auth on shell open
USER ${USERNAME}
RUN echo 'if [ -s /usr/local/share/nvm/nvm.sh ]; then . /usr/local/share/nvm/nvm.sh; fi' >> ~/.zshrc \
 && echo '[ -x /usr/local/bin/gh-auto-auth.sh ] && /usr/local/bin/gh-auto-auth.sh || true' >> ~/.zshrc

CMD ["zsh"]
