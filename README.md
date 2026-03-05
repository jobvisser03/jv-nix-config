# Nix Flake Configuration

This repository contains my personal Nix configuration using flakes, supporting multiple platforms (macOS via nix-darwin and NixOS). It follows a **dendritic flake-parts structure** inspired by [MrSom3body/dotfiles](https://github.com/MrSom3body/dotfiles), where all configuration lives under a unified `modules/` directory.

## Quick Reference

```bash
# macOS (nix-darwin)
darwin-rebuild switch --flake .#macbook-intel
darwin-rebuild switch --flake .#macbook-silicon

# NixOS
sudo nixos-rebuild switch --flake .#larkbox
sudo nixos-rebuild switch --flake .#macbook-intel-nixos
```

## Structure

The configuration follows a **dendritic pattern** where `flake.nix` imports only `modules/default.nix`, which then imports all other modules. Each module registers itself to `flake.modules.{nixos,darwin,homeManager}.*` and configurations compose them declaratively.

```
.
├── flake.nix              # Entry point - imports modules/default.nix
├── flake.lock             # Pinned input versions
├── README.md              # This file
│
├── modules/               # ALL configuration lives here
│   ├── default.nix        # Imports all module categories
│   ├── meta.nix           # Flake metadata
│   │
│   ├── flake/             # Flake infrastructure
│   │   ├── configurations.nix  # NixOS/Darwin system definitions
│   │   ├── flake-parts.nix     # flake-parts setup
│   │   ├── overlays.nix        # Package overlays
│   │   ├── shell.nix           # Development shell
│   │   ├── systems.nix         # Supported systems
│   │   └── treefmt.nix         # Code formatting
│   │
│   ├── hosts/             # Host-specific configurations (self-contained)
│   │   ├── larkbox/           # NixOS homelab server
│   │   │   ├── default.nix
│   │   │   ├── hardware-configuration.nix
│   │   │   └── secrets.nix
│   │   ├── macbook-intel-nixos/  # Intel Mac running NixOS
│   │   │   ├── default.nix
│   │   │   ├── hardware-configuration.nix
│   │   │   ├── secrets.nix
│   │   │   └── firmware/brcm/    # WiFi/Bluetooth firmware
│   │   ├── macbook-intel/        # Intel Mac (macOS/Darwin)
│   │   │   └── default.nix
│   │   └── macbook-silicon/      # Apple Silicon Mac (macOS/Darwin)
│   │       └── default.nix
│   │
│   ├── base/              # Base system configurations
│   │   ├── nixos.nix          # Base NixOS settings
│   │   └── darwin.nix         # Base Darwin settings
│   │
│   ├── nixos/             # NixOS-specific modules
│   │   └── base.nix           # Core NixOS configuration
│   │
│   ├── darwin/            # Darwin-specific modules
│   │   ├── base.nix           # Core Darwin configuration
│   │   └── homebrew.nix       # Homebrew integration
│   │
│   ├── shell/             # Shell configuration modules
│   │   ├── zsh.nix            # Zsh shell
│   │   ├── atuin.nix          # Shell history sync
│   │   ├── oh-my-posh.nix     # Prompt theme
│   │   ├── aliases.nix        # Shell aliases
│   │   ├── direnv.nix         # Directory environments
│   │   ├── eza.nix            # Modern ls replacement
│   │   └── fd.nix             # Modern find replacement
│   │
│   ├── dev/               # Development tools
│   │   ├── git.nix            # Git configuration
│   │   └── tools.nix          # ripgrep, bat, jq, etc.
│   │
│   ├── desktop/           # Desktop environment (NixOS)
│   │   ├── stylix.nix         # System-wide theming
│   │   ├── hyprland.nix       # Hyprland compositor
│   │   ├── waybar.nix         # Status bar
│   │   ├── hyprlock.nix       # Lock screen
│   │   ├── hypridle.nix       # Idle management
│   │   ├── rofi.nix           # Application launcher
│   │   ├── apps.nix           # Desktop applications
│   │   ├── terminals/
│   │   │   ├── wezterm.nix    # WezTerm terminal
│   │   │   └── kitty.nix      # Kitty terminal
│   │   └── browsers/
│   │       └── firefox.nix    # Firefox with extensions
│   │
│   ├── wm/                # Window manager configs (alternative)
│   │   ├── hyprland.nix
│   │   ├── waybar.nix
│   │   ├── hyprlock.nix
│   │   └── hypridle.nix
│   │
│   ├── system/            # System-level modules
│   │   ├── nix.nix            # Nix daemon settings
│   │   ├── power-management.nix
│   │   ├── keyd.nix           # Key remapping
│   │   └── vscode-server.nix  # VS Code remote server
│   │
│   ├── users/             # User account definitions
│   │   ├── job.nix            # Personal user
│   │   └── job-work.nix       # Work user
│   │
│   ├── homelab/           # Homelab services
│   │   ├── flake-module.nix   # Homelab module entry
│   │   ├── options.nix        # Homelab options
│   │   └── services/
│   │       ├── infrastructure.nix   # Caddy, Podman
│   │       ├── immich.nix           # Photo management
│   │       ├── homeassistant.nix    # Home automation
│   │       ├── forgejo.nix          # Git forge
│   │       ├── gitlab.nix           # GitLab
│   │       ├── gitlab-runner.nix    # CI/CD runner
│   │       ├── jellyfin.nix         # Media server
│   │       ├── homepage.nix         # Dashboard
│   │       ├── paperless.nix        # Document management
│   │       ├── radicale.nix         # CalDAV/CardDAV
│   │       ├── spotify-player.nix   # Spotify daemon
│   │       └── cloudflare-ddns.nix  # Dynamic DNS
│   │
│   ├── rclone/            # Cloud storage mounts
│   │   └── default.nix
│   │
│   └── sops/              # Secret management
│       └── default.nix
│
├── secrets/               # SOPS-encrypted secrets
│   ├── larkbox.yaml
│   └── shared.yaml
│
└── non-nix-configs/       # Non-Nix configuration files
```

## How It Works

### Dendritic Pattern

The configuration uses a **dendritic (tree-like) structure** with flake-parts:

1. **`flake.nix`** imports only `modules/default.nix`
2. **`modules/default.nix`** imports all module categories
3. **Each module** registers itself to `flake.modules.{nixos,darwin,homeManager}.<name>`
4. **`modules/flake/configurations.nix`** composes modules into system configurations

### Module Registration

Modules register themselves to be available for composition:

```nix
# modules/shell/zsh.nix
{...}: {
  # Register for NixOS systems
  flake.modules.nixos.zsh = {...}: {
    programs.zsh.enable = true;
    # ...
  };

  # Register for home-manager
  flake.modules.homeManager.zsh = {...}: {
    programs.zsh.enable = true;
    # ...
  };
}
```

### Configuration Composition

Systems are defined by composing modules:

```nix
# modules/flake/configurations.nix
flake.nixosConfigurations = {
  larkbox = mkNixosSystem {
    hostname = "larkbox";
    modules = [
      "zsh" "atuin" "oh-my-posh"  # Shell
      "git" "dev-tools"           # Dev
      "homelab"                   # Services
    ];
  };
};
```

## Available Configurations

| Configuration | Type | Architecture | Description |
|--------------|------|--------------|-------------|
| `larkbox` | NixOS | x86_64-linux | Homelab server (Immich, Home Assistant, etc.) |
| `macbook-intel-nixos` | NixOS | x86_64-linux | Intel MacBook running NixOS with Hyprland |
| `macbook-intel` | Darwin | x86_64-darwin | Intel MacBook running macOS |
| `macbook-silicon` | Darwin | aarch64-darwin | Apple Silicon MacBook running macOS |

## Homelab Architecture

The homelab module (`modules/homelab/`) provides a complete self-hosted services stack with secure remote access via Tailscale.

### Services

- **Immich** - Photo management and backup
- **Home Assistant** - Home automation (with Zigbee2MQTT, Mosquitto)
- **Forgejo** - Git repository hosting
- **Paperless** - Document management
- **Homepage** - Service dashboard
- **Spotify Player** - Headless Spotify daemon

### Access Methods

| Method | URL | Security |
|--------|-----|----------|
| Local LAN | `http://larkbox` | Trusted network |
| Tailscale | `http://100.x.y.z` | WireGuard encrypted |
| MagicDNS | `http://larkbox.tailnet.ts.net` | WireGuard encrypted |

## Adding a New Host

### NixOS Host

1. Create `modules/hosts/<hostname>/default.nix`:
```nix
{...}: {
  flake.modules.nixos."hosts/<hostname>" = {config, ...}: {
    imports = [
      ./hardware-configuration.nix
      ./secrets.nix
    ];
    networking.hostName = "<hostname>";
    # Host-specific config...
  };
}
```

2. Copy `hardware-configuration.nix` from the target machine

3. Add to `modules/flake/configurations.nix`:
```nix
<hostname> = mkNixosSystem {
  hostname = "<hostname>";
  modules = [ "zsh" "git" /* ... */ ];
};
```

4. Import in `modules/hosts/default.nix` (if exists) or ensure auto-import

### Darwin Host

1. Create `modules/hosts/<hostname>/default.nix`:
```nix
{...}: {
  flake.modules.darwin."hosts/<hostname>" = {...}: {
    # Host-specific Darwin settings
  };
}
```

2. Add to `modules/flake/configurations.nix`:
```nix
<hostname> = mkDarwinSystem {
  hostname = "<hostname>";
  system = "aarch64-darwin";  # or x86_64-darwin
  user = "<username>";
  modules = [ "zsh" "git" /* ... */ ];
};
```

## Adding a New Module

1. Create `modules/<category>/<name>.nix`:
```nix
{...}: {
  # For NixOS
  flake.modules.nixos.<name> = {...}: {
    # NixOS configuration
  };

  # For Darwin (if applicable)
  flake.modules.darwin.<name> = {...}: {
    # Darwin configuration
  };

  # For Home Manager (if applicable)
  flake.modules.homeManager.<name> = {...}: {
    # Home Manager configuration
  };
}
```

2. Import in the category's parent or `modules/default.nix`

3. Add to system configurations in `modules/flake/configurations.nix`

## Secrets

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix).

```bash
# Edit host-specific secrets
sops secrets/larkbox.yaml

# Edit shared secrets
sops secrets/shared.yaml
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

# Enter development shell
nix develop

# Clean old generations
sudo nix-collect-garbage --delete-older-than 14d
```

## Setup Instructions

### New NixOS Machine

1. Install NixOS with the standard installer
2. Clone this repo to `~/repos/jv-nix-config`
3. Run: `sudo nixos-rebuild switch --flake ~/repos/jv-nix-config#<hostname>`

### New macOS Machine

1. Install Nix using the [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer)
2. Clone this repo to `~/repos/jv-nix-config`
3. Initial setup: `nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake ~/repos/jv-nix-config#<hostname>`
4. Subsequent updates: `darwin-rebuild switch --flake ~/repos/jv-nix-config#<hostname>`

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

- [flake-parts Documentation](https://flake.parts/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Language Basics](https://nix.dev/tutorials/nix-language)
- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [MrSom3body/dotfiles](https://github.com/MrSom3body/dotfiles) - Inspiration for dendritic structure
