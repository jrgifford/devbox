# Devbox

A CLI tool for managing a multipass development VM provisioned with Ansible.

## Features

- **Ubuntu 24.04 LTS** VM with 8 CPUs, 16GB RAM, 100GB disk
- **Version managers**: mise (Ruby, Python, Go, Node, etc.)
- **Language runtimes**: uv (Python), bun (JavaScript), rustup (Rust)
- **Shell**: zsh with oh-my-zsh and powerlevel10k theme
- **AI coding agents**: Claude Code, Codex CLI, Gemini CLI
- **Dev tools**: Docker, GitHub CLI
- **Networking**: Tailscale (auto-joins your network)

## Prerequisites

- [Multipass](https://multipass.run/) (`sudo snap install multipass`)
- [Ansible](https://docs.ansible.com/) (`mise use -g ansible-core` or `pip install ansible`)
- Ansible community.general collection (`ansible-galaxy collection install community.general`)

## Quick Start

```bash
# Set your Tailscale auth key (or add to ~/.secrets)
export TAILSCALE_AUTH_KEY=tskey-auth-xxxxx

# Create and provision the VM
./devbox start

# Enter the VM
./devbox login
```

## Commands

| Command | Description |
|---------|-------------|
| `./devbox start` | Create VM (if needed) and provision with Ansible |
| `./devbox stop` | Stop the VM |
| `./devbox login` | Shell into the VM (multipass shell) |
| `./devbox ssh` | Direct SSH into the VM |
| `./devbox mount <src> <dst>` | Mount host directory into VM |
| `./devbox status` | Show VM info (including Tailscale IP) |
| `./devbox destroy` | Delete VM (with confirmation) |
| `./devbox provision` | Re-run Ansible provisioning |

## Configuration

### Tailscale Auth Key

Set your Tailscale auth key in one of these locations:
- Environment variable: `TAILSCALE_AUTH_KEY`
- File: `~/.secrets` (sourced automatically)
- File: `.env` in the project directory

Get an auth key from [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys).

### VM Resources

Edit the variables at the top of `./devbox` to customize:

```bash
VM_CPUS="8"
VM_MEMORY="16G"
VM_DISK="100G"
```

## Installed Tools

After provisioning, these tools are available in the VM:

| Tool | Purpose |
|------|---------|
| mise | Version manager for multiple languages |
| uv | Fast Python package manager |
| bun | JavaScript runtime and package manager |
| rustup | Rust toolchain manager |
| Docker | Container runtime |
| gh | GitHub CLI |
| claude | Claude Code AI assistant |
| codex | OpenAI Codex CLI |
| gemini | Google Gemini CLI |

## Project Structure

```
.
├── devbox                  # Main CLI script
├── cloud-init.yaml         # VM bootstrap configuration
├── ansible.cfg             # Ansible configuration
├── inventory/hosts.ini     # Dynamic inventory (generated)
├── group_vars/all.yml      # Shared Ansible variables
├── playbooks/site.yml      # Main Ansible playbook
└── roles/
    ├── base/               # System packages, timezone
    ├── docker/             # Docker Engine
    ├── tailscale/          # Tailscale VPN
    ├── shell/              # zsh, oh-my-zsh, powerlevel10k
    ├── mise/               # mise version manager
    ├── runtimes/           # uv, bun, rustup
    └── ai-agents/          # Claude Code, Codex, Gemini
```

## Acknowledgments

Inspired by [agentic_coding_flywheel_setup](https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup) by Jeffrey Emanuel - a system setup tool that transforms a fresh VPS into a fully-armed agentic coding environment.

## License

MIT
