# Configuration builders for NixOS and Darwin systems
{
  config,
  inputs,
  ...
}: let
  # Load both NixOS and home-manager modules for a given list of module names
  loadNixosAndHmModules = modules: user:
    (builtins.map (module: config.flake.modules.nixos.${module} or {}) modules)
    ++ [
      {
        imports = [inputs.home-manager.nixosModules.home-manager];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-backup";
          extraSpecialArgs = {inherit inputs;};
          users.${user}.imports =
            builtins.map (module: config.flake.modules.homeManager.${module} or {}) modules;
        };
      }
    ];

  # Load Darwin modules with home-manager integration
  loadDarwinAndHmModules = modules: user:
    (builtins.map (module: config.flake.modules.darwin.${module} or {}) modules)
    ++ [
      {
        imports = [inputs.home-manager.darwinModules.home-manager];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-backup";
          extraSpecialArgs = {inherit inputs;};
          users.${user}.imports =
            builtins.map (module: config.flake.modules.homeManager.${module} or {}) modules;
        };
      }
    ];

  # Create a NixOS system configuration
  mkNixosSystem = {
    hostname,
    system ? "x86_64-linux",
    modules ? [],
    user ? "job",
    extraModules ? [],
  }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
        username = user;
      };
      modules =
        [
          # Always include base modules
          config.flake.modules.nixos.base or {}
          # Host-specific module
          config.flake.modules.nixos."hosts/${hostname}" or {}
        ]
        ++ (loadNixosAndHmModules modules user)
        ++ extraModules;
    };

  # Create a Darwin system configuration
  mkDarwinSystem = {
    hostname,
    system,
    modules ? [],
    user,
    extraModules ? [],
  }:
    inputs.darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
        username = user;
      };
      modules =
        [
          # Always include base darwin module
          config.flake.modules.darwin.base or {}
          # Host-specific module
          config.flake.modules.darwin."hosts/${hostname}" or {}
        ]
        ++ (loadDarwinAndHmModules modules user)
        ++ extraModules;
    };
in {
  # Export functions to flake.lib
  flake.lib = {
    inherit loadNixosAndHmModules loadDarwinAndHmModules mkNixosSystem mkDarwinSystem;
  };

  # Define all system configurations here
  flake.nixosConfigurations = {
    # Homelab server
    larkbox = mkNixosSystem {
      hostname = "larkbox";
      system = "x86_64-linux";
      user = "job";
      modules = [
        # Base modules
        "nix"
        "home"
        "sops"
        "user-job"
        "power-management"
        "vscode-server"
        # Shell
        "zsh"
        "atuin"
        "oh-my-posh"
        "aliases"
        "direnv"
        "eza"
        "fd"
        # Dev tools
        "git"
        "dev-tools"
        # Homelab
        "homelab"
        # Desktop (Hyprland)
        "stylix"
        "hyprland"
        "waybar"
        "hyprlock"
        "hypridle"
        "rofi"
        "wezterm"
        "kitty"
        "firefox"
        "desktop-apps"
      ];
      extraModules = [
        inputs.sops-nix.nixosModules.sops
        inputs.stylix.nixosModules.stylix
        inputs.nixos-hardware.nixosModules.aoostar-r1-n100
      ];
    };

    # MacBook running NixOS
    macbook-intel-nixos = mkNixosSystem {
      hostname = "macbook-intel-nixos";
      system = "x86_64-linux";
      user = "job";
      modules = [
        # Base modules
        "nix"
        "home"
        "sops"
        "user-job"
        "vscode-server"
        # Shell
        "zsh"
        "atuin"
        "oh-my-posh"
        "aliases"
        "direnv"
        "eza"
        "fd"
        # Dev tools
        "git"
        "dev-tools"
        # Desktop (Hyprland)
        "stylix"
        "hyprland"
        "waybar"
        "hyprlock"
        "hypridle"
        "rofi"
        "wezterm"
        "kitty"
        "firefox"
        "desktop-apps"
      ];
      extraModules = [
        inputs.sops-nix.nixosModules.sops
        inputs.stylix.nixosModules.stylix
        inputs.nixos-hardware.nixosModules.apple-t2
      ];
    };

    # MacBook running NixOS
    macbook-intel-nixos-sooph = mkNixosSystem {
      hostname = "macbook-intel-nixos-sooph";
      system = "x86_64-linux";
      user = "sooph";
      modules = [
        # Base modules
        "nix"
        "home"
        "sops"
        "user-sooph"
        "vscode-server"
        # Shell
        "zsh"
        "atuin"
        "oh-my-posh"
        "aliases"
        "direnv"
        "eza"
        "fd"
        # Dev tools
        "git"
        "dev-tools"
        # Desktop
        "wezterm"
        "firefox"
        "desktop-apps"
      ];
    };
  };

  # Darwin configurations
  flake.darwinConfigurations = {
    # Personal MacBook (Intel)
    macbook-intel = mkDarwinSystem {
      hostname = "macbook-intel";
      system = "x86_64-darwin";
      user = "job";
      modules = [
        # Base modules
        "nix"
        "home"
        "home-darwin"
        "homebrew"
        "user-job"
        # Shell
        "zsh"
        "atuin"
        "oh-my-posh"
        "aliases"
        "direnv"
        "eza"
        "fd"
        # Dev tools
        "git"
        "dev-tools"
        # Terminals
        "wezterm"
        "kitty"
        # Desktop apps
        "desktop-apps"
      ];
    };

    # Work MacBook (Apple Silicon)
    macbook-silicon = mkDarwinSystem {
      hostname = "macbook-silicon";
      system = "aarch64-darwin";
      user = "job.visser";
      modules = [
        # Base modules
        "nix"
        "home"
        "home-darwin"
        "homebrew"
        "user-job-work"
        # Shell
        "zsh"
        "atuin"
        "oh-my-posh"
        "aliases"
        "direnv"
        "eza"
        "fd"
        # Dev tools
        "git"
        "dev-tools"
        # Terminals
        "wezterm"
        "kitty"
        # Desktop apps
        "desktop-apps"
      ];
    };
  };
}
