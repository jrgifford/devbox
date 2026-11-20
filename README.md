# Devbox

A CLI tool for managing a multipass development VM provisioned with Ansible.

## Features

- **Ubuntu 25.10** VM with 8 CPUs, 16GB RAM, 100GB disk
- **Language runtimes via mise**: Ruby, Python, Node.js, Go, Rust
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

### Language Versions

Edit the existing entries under `mise_runtimes` in `group_vars/all.yml` to customize mise-managed versions. For example, the Ruby entry is:

```yaml
  - name: ruby
    version: "3.4.13"
```

## Installed Tools

After provisioning, these tools are available in the VM:

| Tool | Purpose |
|------|---------|
| mise | Version manager for multiple languages |
| ruby | Ruby runtime (via mise) |
| python | Python runtime (via mise) |
| node | Node.js runtime (via mise) |
| go | Go runtime (via mise) |
| rust/cargo | Rust toolchain (via mise) |
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
    ├── base/               # System packages, build deps
    ├── docker/             # Docker Engine
    ├── tailscale/          # Tailscale VPN
    ├── shell/              # zsh, oh-my-zsh, powerlevel10k
    ├── mise/               # mise + Ruby, Python, Node, Go, Rust
    └── ai-agents/          # Claude Code, Codex, Gemini
```

## License

MIT
