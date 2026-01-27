# syntax=docker/dockerfile:1.4
# Devbox container - built with Ansible, one role at a time for layer caching

FROM ubuntu:24.04 AS base

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install Ansible and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ansible \
    python3 \
    python3-pip \
    sudo \
    curl \
    git \
    ca-certificates \
    openssh-client \
    tzdata \
    gnupg \
    && rm -rf /var/lib/apt/lists/* \
    && ansible-galaxy collection install community.general

# Configure dev user with sudo access (ubuntu user exists in base image)
ARG DEV_USER=ubuntu
ARG DEV_USER_HOME=/home/ubuntu
RUN id ${DEV_USER} &>/dev/null || useradd -m -s /bin/bash -d ${DEV_USER_HOME} ${DEV_USER} \
    && echo "${DEV_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p ${DEV_USER_HOME} && chown ${DEV_USER}:${DEV_USER} ${DEV_USER_HOME}

# Copy Ansible configuration
WORKDIR /ansible
COPY ansible.cfg .
COPY group_vars/ group_vars/
COPY roles/ roles/
COPY playbooks/ playbooks/

# Create container-specific inventory
RUN mkdir -p inventory && printf '[all]\nlocalhost ansible_connection=local\n' > inventory/hosts.ini

# ============================================================
# Role: base - System packages and build dependencies
# ============================================================
FROM base AS role-base
RUN ansible-playbook playbooks/site.yml --tags base \
    -e "dev_user=${DEV_USER:-ubuntu}" \
    -e "dev_user_home=${DEV_USER_HOME:-/home/ubuntu}" \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Role: docker - Docker CLI only (for container mode)
# ============================================================
FROM role-base AS role-docker
RUN ansible-playbook playbooks/site.yml --tags docker \
    -e "dev_user=${DEV_USER:-ubuntu}" \
    -e "dev_user_home=${DEV_USER_HOME:-/home/ubuntu}" \
    -e "docker_cli_only=true" \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Role: shell - zsh, oh-my-zsh, powerlevel10k
# ============================================================
FROM role-docker AS role-shell
RUN ansible-playbook playbooks/site.yml --tags shell \
    -e "dev_user=${DEV_USER:-ubuntu}" \
    -e "dev_user_home=${DEV_USER_HOME:-/home/ubuntu}" \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Role: mise - Language runtimes and CLI tools
# ============================================================
FROM role-shell AS role-mise
ARG GITHUB_TOKEN=""
RUN GITHUB_TOKEN=${GITHUB_TOKEN} ansible-playbook playbooks/site.yml --tags mise \
    -e "dev_user=${DEV_USER:-ubuntu}" \
    -e "dev_user_home=${DEV_USER_HOME:-/home/ubuntu}" \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# ============================================================
# Role: tools - Additional tools (git-lfs)
# ============================================================
FROM role-mise AS role-tools
RUN ansible-playbook playbooks/site.yml --tags tools \
    -e "dev_user=${DEV_USER:-ubuntu}" \
    -e "dev_user_home=${DEV_USER_HOME:-/home/ubuntu}" \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Role: ai-agents - Claude Code, Codex CLI, Gemini CLI
# ============================================================
FROM role-tools AS role-ai-agents
RUN ansible-playbook playbooks/site.yml --tags ai-agents \
    -e "dev_user=${DEV_USER:-ubuntu}" \
    -e "dev_user_home=${DEV_USER_HOME:-/home/ubuntu}" \
    && rm -rf /tmp/*

# ============================================================
# Final image - clean up and set runtime config
# ============================================================
FROM role-ai-agents AS final

# Clean up Ansible files (not needed at runtime)
RUN rm -rf /ansible

# Set up runtime environment
ENV HOME=/home/ubuntu
ENV PATH="/home/ubuntu/.local/bin:/home/ubuntu/.local/share/mise/shims:${PATH}"

WORKDIR /home/ubuntu
USER ubuntu

# Default to zsh
CMD ["/usr/bin/zsh"]
