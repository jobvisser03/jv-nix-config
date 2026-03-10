# Nix Flake Configuration

This repository contains my personal Nix configuration using flakes, supporting multiple platforms (macOS via nix-darwin and NixOS). It follows a **dendritic flake-parts structure** using [import-tree](https://github.com/vic/import-tree), inspired by [MrSom3body/dotfiles](https://github.com/MrSom3body/dotfiles) and [mightyiam/dendritic](https://github.com/mightyiam/dendritic), where all configuration lives under a unified `modules/` directory.

## Quick Reference

```bash
# macOS (nix-darwin)
darwin-rebuild switch --flake .#macbook-intel
darwin-rebuild switch --flake .#macbook-silicon

# NixOS
sudo nixos-rebuild switch --flake .#larkbox
sudo nixos-rebuild switch --flake .#macbook-intel-nixos
sudo nixos-rebuild switch --flake .#macbook-intel-nixos-sooph
```

## Structure

The configuration follows a **dendritic pattern** using `import-tree` to auto-import all `.nix` files from `modules/`. Each module registers itself to `flake.modules.{nixos,darwin,homeManager}.*` and configurations compose them declaratively. Paths containing `/_` are excluded from auto-import.

```
.
├── flake.nix              # Entry point - uses import-tree ./modules
├── flake.lock             # Pinned input versions
├── README.md              # This file
├── .sops.yaml             # SOPS key configuration
│
├── modules/               # ALL configuration lives here (auto-imported)
│   ├── meta.nix           # Global identity and appearance defaults
│   │
│   ├── flake/             # Flake infrastructure
│   │   ├── configurations.nix  # NixOS/Darwin system definitions
│   │   ├── flake-parts.nix     # flake-parts setup and options
│   │   ├── overlays.nix        # Package overlays
│   │   ├── shell.nix           # Development shell
│   │   ├── systems.nix         # Supported systems
│   │   └── treefmt.nix         # Code formatting
│   │
│   ├── hosts/             # Host-specific configurations
│   │   ├── larkbox/           # NixOS homelab server
│   │   │   ├── default.nix
│   │   │   ├── _hardware-configuration.nix
│   │   │   └── _secrets.nix
│   │   ├── macbook-intel-nixos/  # Intel Mac running NixOS
│   │   │   ├── default.nix
│   │   │   ├── _hardware-configuration.nix
│   │   │   ├── _secrets.nix
│   │   │   ├── _t2-suspend/      # T2 suspend/resume fix module
│   │   │   └── _firmware/brcm/   # WiFi/Bluetooth firmware blobs
│   │   ├── macbook-intel-nixos-sooph/  # Intel Mac running NixOS (sooph)
│   │   │   ├── default.nix
│   │   │   └── _hardware-configuration.nix
│   │   ├── macbook-intel/        # Intel Mac (macOS/Darwin)
│   │   │   └── default.nix
│   │   └── macbook-silicon/      # Apple Silicon Mac (macOS/Darwin)
│   │       └── default.nix
│   │
│   ├── base/              # Shared base modules (all platforms)
│   │   ├── home.nix           # Home-manager base config
│   │   ├── nix.nix            # Nix daemon settings
│   │   └── sops.nix           # SOPS base setup
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
│   ├── desktop/           # Desktop environment (NixOS/Hyprland)
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
│   ├── system/            # System-level modules
│   │   ├── power-management.nix
│   │   └── vscode-server.nix  # VS Code remote server
│   │
│   ├── users/             # User account definitions
│   │   ├── job.nix            # Personal user (NixOS + Darwin + HM)
│   │   ├── job-work.nix       # Work user variant
│   │   └── sooph.nix          # Secondary user
│   │
│   ├── homelab/           # Homelab services
│   │   ├── flake-module.nix   # Homelab module entry point
│   │   ├── _options.nix       # Shared homelab NixOS options
│   │   └── _services/         # Individual service definitions
│   │       ├── infrastructure.nix   # Shared infra (reverse proxy, etc.)
│   │       ├── immich.nix           # Photo management
│   │       ├── homeassistant.nix    # Home automation
│   │       ├── forgejo.nix          # Git forge
│   │       ├── gitlab.nix           # GitLab
│   │       ├── gitlab-runner.nix    # CI/CD runner
│   │       ├── jellyfin.nix         # Media server
│   │       ├── homepage.nix         # Service dashboard
│   │       ├── paperless.nix        # Document management
│   │       ├── radicale.nix         # CalDAV/CardDAV
│   │       ├── spotify-player.nix   # Spotify daemon
│   │       └── cloudflare-ddns.nix  # Dynamic DNS
│   │
│   ├── _rclone/           # Cloud storage mounts (internal)
│   │   └── default.nix
│   ├── _sops/             # Secret management (internal)
│   │   └── default.nix
│   └── _wm-scripts/       # WM helper scripts (internal)
│       └── get_battery_info.sh
│
├── secrets/               # SOPS-encrypted secrets
│   ├── larkbox.yaml
│   ├── mac-intel-nixos.yaml
│   └── shared.yaml
│
└── non-nix-configs/       # Non-Nix configuration files
    ├── wezterm.lua
    ├── raycast_config.rayconfig
    └── *.png               # Wallpapers
```

> **Note on `_` prefixes:** Paths containing `/_` are automatically excluded by `import-tree`. This includes `_rclone/`, `_sops/`, `_wm-scripts/`, `_firmware/`, `_options.nix`, `_services/`, `_hardware-configuration.nix`, and `_secrets.nix`. These internal files are imported explicitly where needed.

## How It Works

### Dendritic Pattern

The configuration uses a **dendritic (tree-like) structure** with [import-tree](https://github.com/vic/import-tree) and flake-parts:

1. **`flake.nix`** calls `inputs.import-tree ./modules` — all `.nix` files are auto-imported
2. **Paths with `/_`** are excluded (hardware configs, secrets, internal modules)
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

Systems are defined by composing modules. The `username` argument is automatically passed to all NixOS/Darwin modules via `specialArgs`:

```nix
# modules/flake/configurations.nix
flake.nixosConfigurations = {
  macbook-intel-nixos = mkNixosSystem {
    hostname = "macbook-intel-nixos";
    user = "job";           # exposed as `username` in all modules
    modules = [
      "zsh" "atuin" "oh-my-posh"  # Shell
      "git" "dev-tools"           # Dev
      "hyprland" "waybar"         # Desktop
    ];
  };
};
```

## Available Configurations

| Configuration | Type | Architecture | User | Description |
|---|---|---|---|---|
| `larkbox` | NixOS | x86_64-linux | job | Homelab server + Hyprland desktop |
| `macbook-intel-nixos` | NixOS | x86_64-linux | job | Intel MacBook running NixOS with Hyprland |
| `macbook-intel-nixos-sooph` | NixOS | x86_64-linux | sooph | Intel MacBook running NixOS (sooph's account) |
| `macbook-intel` | Darwin | x86_64-darwin | job | Intel MacBook running macOS |
| `macbook-silicon` | Darwin | aarch64-darwin | job.visser | Apple Silicon MacBook running macOS |

## Homelab Architecture

The homelab module (`modules/homelab/`) provides a complete self-hosted services stack. Service definitions live under `_services/` and are composed in `flake-module.nix`.

### Services

- **Immich** - Photo management and backup
- **Home Assistant** - Home automation (with Zigbee2MQTT, Mosquitto)
- **Forgejo** - Git repository hosting
- **Jellyfin** - Media server
- **Paperless** - Document management
- **Homepage** - Service dashboard
- **Radicale** - CalDAV/CardDAV server
- **Spotify Player** - Headless Spotify daemon
- **GitLab / GitLab Runner** - CI/CD
- **Cloudflare DDNS** - Dynamic DNS updates

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
  flake.modules.nixos."hosts/<hostname>" = {config, pkgs, username, ...}: {
    imports = [
      ./_hardware-configuration.nix
      ./_secrets.nix
    ];
    networking.hostName = "<hostname>";
    # Host-specific config...
  };
}
```

2. Copy `hardware-configuration.nix` from the target machine (prefix with `_`)

3. Add to `modules/flake/configurations.nix`:
```nix
<hostname> = mkNixosSystem {
  hostname = "<hostname>";
  user = "<username>";
  modules = [ "zsh" "git" /* ... */ ];
};
```

The host module will be auto-imported by `import-tree`.

### Darwin Host

1. Create `modules/hosts/<hostname>/default.nix`:
```nix
{...}: {
  flake.modules.darwin."hosts/<hostname>" = {username, ...}: {
    users.users.${username}.home = "/Users/${username}";
    system.primaryUser = username;
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

The host module will be auto-imported by `import-tree`.

## Adding a New Module

1. Create `modules/<category>/<name>.nix` — it will be auto-imported:
```nix
{...}: {
  # For NixOS
  flake.modules.nixos.<name> = {pkgs, lib, config, ...}: {
    # NixOS configuration
  };

  # For Darwin (if applicable)
  flake.modules.darwin.<name> = {pkgs, lib, config, ...}: {
    # Darwin configuration
  };

  # For Home Manager (if applicable)
  flake.modules.homeManager.<name> = {pkgs, lib, config, ...}: {
    # Home Manager configuration
  };
}
```

2. Add the module name to the relevant system configurations in `modules/flake/configurations.nix`

That's it — `import-tree` will auto-import the new module file.

## Secrets

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix). Encrypted YAML files live in `secrets/` and are referenced via the `_sops/` module.

```bash
# Edit host-specific secrets
sops secrets/larkbox.yaml
sops secrets/mac-intel-nixos.yaml

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
3. Initial setup: `nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake ~/repos/jv-nix-config#<hostname>`
4. Subsequent updates: `darwin-rebuild switch --flake ~/repos/jv-nix-config#<hostname>`

## Troubleshooting

### T2 Mac Suspend/Resume (macbook-intel-nixos)

T2 Macs have broken suspend/resume due to PipeWire holding audio handles to `apple-bce`. On resume, the driver maps audio at a new MMIO address, causing stale handles and broken input devices.

The `_t2-suspend` module fixes this by:
1. Stopping PipeWire before suspend (releases audio handles)
2. Unloading `apple-bce` and WiFi modules
3. Reloading modules on resume and restarting PipeWire

Configuration in `modules/hosts/macbook-intel-nixos/default.nix`:
```nix
hardware.apple-t2-suspend = {
  enable = true;
  useDeepSleep = true;      # mem_sleep_default=deep
  disableAspm = true;       # pcie_aspm=off (improves stability)
  unloadAppleBce = true;    # Unload/reload apple-bce module
  stopAudio = true;         # Stop PipeWire before suspend
};
```

Check logs: `journalctl -u suspend-fix-t2`

References:
- https://github.com/lucadibello/T2Linux-Suspend-Fix
- https://github.com/t2linux/T2-Debian-and-Ubuntu-Kernel/issues/53

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
