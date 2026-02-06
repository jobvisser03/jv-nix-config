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
