# Nix Flake Configuration

This repository contains my personal Nix configuration using flakes, supporting multiple platforms (macOS via nix-darwin and NixOS).

## Quick Reference

```bash
# macOS (nix-darwin)
darwin-rebuild switch --flake .#mac-intel-host
darwin-rebuild switch --flake .#mac-apple-silicon-host

# NixOS
sudo nixos-rebuild switch --flake .#linux-larkbox-host
sudo nixos-rebuild switch --flake .#mac-intel-nixos-host

# Home Manager (standalone)
home-manager switch --flake .#mac-intel-hm
home-manager switch --flake .#mac-apple-silicon-hm
```

## Structure

```
.
├── flake.nix              # Main entry point - defines all configurations
├── README.md              # This file
│
├── home/                  # Home Manager configurations
│   ├── shared-home.nix    # Common home config (imports all others)
│   ├── core-packages.nix  # Base packages for all systems
│   ├── home-nixos.nix     # NixOS-specific home config (Hyprland, etc.)
│   ├── home-mac.nix       # macOS-specific home config
│   ├── alias.nix          # Shell aliases
│   └── programs/          # Program-specific configs
    │       ├── default.nix    # Aggregates all program configs
    │       ├── browser.nix    # Firefox settings
    │       ├── shell.nix      # zsh, atuin, direnv, eza, fzf-tab, oh-my-posh, wezterm, kitty
    │       └── dev-tools.nix  # git, awscli, ripgrep, bat, broot, etc.
│
├── hosts/                 # Host-specific configurations
│   ├── common/            # Shared host configurations
│   │   ├── darwin/        # Common macOS settings (Homebrew, Touch ID, etc.)
│   │   └── nixos/         # Common NixOS settings (timezone, locale, avahi, etc.)
│   │
│   ├── linux-larkbox-host/    # NixOS homelab server
│   │   ├── configuration.nix  # System configuration
│   │   ├── hardware-configuration.nix
│   │   ├── home.nix       # Host-specific home packages
│   │   └── secrets.nix    # SOPS secrets configuration
│   │
│   ├── mac-intel-nixos-host/  # Intel Mac running NixOS
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix
│   │
│   ├── mac-intel-host/        # Intel Mac running macOS
│   │   └── system.nix     # Host-specific Darwin settings
│   │
│   └── mac-apple-silicon-host/  # Apple Silicon Mac
│       └── system.nix
│
├── modules/               # Reusable NixOS modules
│   ├── default.nix
│   ├── homelab/          # Homelab services (Immich, Home Assistant, etc.)
│   ├── sops/             # Secret management configuration
│   ├── system/           # System-level modules (nix settings, power management)
│   └── wm/               # Window manager configs (Hyprland, Waybar, etc.)
│
├── profiles/              # Configuration profiles
│   ├── default.nix
│   ├── desktop.nix       # Desktop environment settings
│   └── stylix.nix        # Theming and styling
│
└── secrets/               # SOPS-encrypted secrets
    ├── larkbox.yaml
    └── shared.yaml
```

## Homelab Architecture

The homelab module (`modules/homelab/`) provides a complete self-hosted services stack with secure remote access. The architecture is designed for simplicity and security, using HTTP locally while leveraging Tailscale's WireGuard encryption for remote access.

### Components

#### 1. **Tailscale** - Secure VPN Access Layer
- **Purpose**: Encrypted WireGuard tunnel for secure remote access
- **Configuration**: Enabled on all NixOS systems via `hosts/common/nixos/default.nix`
- **Network**: Creates `tailscale0` interface (trusted in firewall)
- **Access**: Services accessible via Tailscale IPs (e.g., `http://100.x.y.z`) or MagicDNS hostnames

#### 2. **Caddy** - HTTP Reverse Proxy
- **Purpose**: Single entry point routing traffic to backend services
- **Port**: Listens on port 80 (HTTP only)
- **Configuration**: `modules/homelab/services/default.nix`
- **Features**: 
  - No automatic HTTPS (`auto_https off`)
  - Virtual host routing to different services
  - Handles WebSocket proxying for Home Assistant
- **Why HTTP?**: Encryption provided by Tailscale tunnel; HTTPS would be redundant

#### 3. **Podman** - Container Runtime
- **Purpose**: Runs containerized services (Home Assistant, etc.)
- **Network**: Custom `homelab` network with DNS resolution between containers
- **Configuration**: Automatic container restart, pruning, and DNS-enabled networking

#### 4. **Services**
Available services in `modules/homelab/services/`:
- **GitLab** - Git repository management (port 8929)
- **GitLab Runner** - CI/CD executor
- **Immich** - Photo management and backup (port 2283)
- **Jellyfin** - Media server (port 8096)
- **Home Assistant** - Home automation and IoT (port 8123)
  - Mosquitto MQTT broker
  - Zigbee2MQTT for Zigbee devices
- **Homepage** - Service dashboard (port 80, root `/`)
- **Radicale** - CalDAV/CardDAV server (optional, port 5232)
- **rclone** - Cloud storage mounts (pCloud integration)

### Request Flow

#### Local Network Access
```
User (192.168.x.x)
    ↓
    [Port 80] → Caddy Reverse Proxy
                    ↓
        ┌───────────┼───────────┬─────────────┬──────────────┐
        ↓           ↓           ↓             ↓              ↓
    GitLab:8929  Immich:2283  Jellyfin:8096  HomeAssistant  Homepage
                                              (Podman)       (root /)
```

**Path**: `http://larkbox` or `http://192.168.x.x` → Caddy routes based on port/path → Backend service

#### Remote Access via Tailscale
```
User (anywhere with Tailscale)
    ↓
    Tailscale VPN (WireGuard encrypted tunnel)
    ↓
    [tailscale0 interface → 100.x.y.z]
    ↓
    [Port 80] → Caddy Reverse Proxy
                    ↓
        ┌───────────┼───────────┬─────────────┬──────────────┐
        ↓           ↓           ↓             ↓              ↓
    GitLab:8929  Immich:2283  Jellyfin:8096  HomeAssistant  Homepage
                                              (Podman)       (root /)
```

**Path**: `http://100.x.y.z` or `http://larkbox.tailnet.ts.net` → Tailscale encrypted tunnel → Caddy → Backend service

**Security**: All traffic encrypted at network layer (WireGuard), no HTTPS overhead needed

### Network & Firewall Configuration

#### Firewall Rules (`hosts/linux-larkbox-host/configuration.nix`)
```nix
networking.firewall = {
  enable = true;
  trustedInterfaces = [ "tailscale0" ];  # Trust all Tailscale traffic
  allowedUDPPorts = [ 41641 ];           # Tailscale connection establishment
  # Port 80 opened by homelab module
};
```

#### Service Routing
- **Caddy** listens on `0.0.0.0:80` (all interfaces, including Tailscale)
- **Backend services** listen on `localhost` or internal Podman network
- **Tailscale interface** is trusted → no additional firewall rules needed
- **Local network** accesses same port 80 → transparent routing

### Adding a Homelab Service

1. **Create service module**: `modules/homelab/services/<service-name>/default.nix`
2. **Define options**: Port, enable flag, storage paths
3. **Configure backend**: Systemd service or Podman container
4. **Add Caddy virtual host** (if using reverse proxy):
   ```nix
   services.caddy.virtualHosts."http://:${toString cfg.port}" = {
     extraConfig = ''
       reverse_proxy localhost:${toString internalPort}
     '';
   };
   ```
5. **Import in** `modules/homelab/services/default.nix`
6. **Enable in host config**: `homelab.services.<service-name>.enable = true;`

### Access Methods

| Method | URL | Security | Use Case |
|--------|-----|----------|----------|
| **Local LAN** | `http://larkbox` or `http://192.168.x.x` | Unencrypted (trusted network) | Home network access |
| **Tailscale IP** | `http://100.x.y.z` | WireGuard encrypted | Remote access from phone/laptop |
| **MagicDNS** | `http://larkbox.tailnet.ts.net` | WireGuard encrypted | Remote access with friendly hostname |

### First-Time Tailscale Setup

After deploying the configuration:

```bash
# Authenticate with Tailscale (opens browser)
sudo tailscale up

# Check status and get your IP
tailscale status
tailscale ip -4

# Enable MagicDNS (optional, in Tailscale admin console)
# Settings → DNS → Enable MagicDNS
```

Then access services from anywhere: `http://100.x.y.z` or `http://larkbox`

## Adding a New Host

### NixOS Host

1. Create directory: `hosts/<hostname>/`
2. Copy `hardware-configuration.nix` from the target machine
3. Create `configuration.nix` importing common modules and setting host-specific options
4. Optionally create `home.nix` for host-specific packages
5. Add to `flake.nix` in `nixosConfigurations`

Example `configuration.nix`:
```nix
{
  imports = [
    ./hardware-configuration.nix
    ../common/nixos
    ../../modules/system
    ../../profiles
    # ... other imports
  ];
  
  networking.hostName = "<hostname>";
  # Host-specific config...
}
```

### macOS Host

1. Create directory: `hosts/<hostname>/`
2. Create `system.nix` with host-specific settings (architecture, user, etc.)
3. Add to `flake.nix` in `darwinConfigurations`

## Home Manager Structure

Home configurations are split logically for maintainability:

- **`shared-home.nix`** - Entry point, imports all home configs
- **`core-packages.nix`** - Base packages available on all systems
- **`home-nixos.nix`** - NixOS-specific (Hyprland, Wayland apps, Linux packages)
- **`home-mac.nix`** - macOS-specific packages
- **`programs/`** - Individual program configurations organized by category:
  - `browser.nix` - Firefox with extensions and search engines
  - `shell.nix` - zsh, atuin (history), direnv, eza, fzf-tab, oh-my-posh (prompt with hostname), wezterm, kitty, pandoc, zoxide
  - `dev-tools.nix` - git, awscli, ripgrep, bat, broot, btop, jq

## Secrets

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix).

```bash
# Edit host-specific secrets
sops secrets/larkbox.yaml

# Edit shared secrets
sops secrets/shared.yaml
```

## Setup Instructions

### New NixOS Machine

1. Install NixOS with the standard installer
2. Clone this repo to `~/repos/jv-nix-config`
3. Run: `sudo nixos-rebuild switch --flake ~/repos/jv-nix-config#<hostname>`

### New macOS Machine

1. Install Nix using the [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer)
2. Clone this repo to `~/repos/jv-nix-config`
3. Initial setup: `nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake ~/repos/jv-nix-config`
4. Subsequent updates: `darwin-rebuild switch --flake ~/repos/jv-nix-config`

### Home Manager (Standalone)

Useful for non-NixOS Linux or when not using nix-darwin on macOS:

```bash
nix --experimental-features 'nix-command flakes' run home-manager/master -- init --switch
home-manager switch --flake /Users/job/repos/jv-nix-config#<config-name>
```

## Maintenance

```bash
# Check configuration
nix flake check

# Format code
nix fmt

# Show available configurations
nix flake show

# Update all inputs
nix flake update

# Clean old generations
sudo nix-collect-garbage --delete-older-than 14d
```

## Troubleshooting

### Trusted Users Warning

If you see warnings about untrusted substituters with Determinate Nix:

```bash
echo "trusted-users = root <your-username>" | sudo tee -a /etc/nix/nix.custom.conf
sudo launchctl stop org.nixos.nix-daemon && sudo launchctl start org.nixos.nix-daemon
```

### Cachix Authentication

```bash
cachix authtoken <your-token>
```

## Resources

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Language Basics](https://nix.dev/tutorials/nix-language)
- [Flakes Wiki](https://nixos.wiki/wiki/Flakes)
- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [sops-nix](https://github.com/Mic92/sops-nix)
