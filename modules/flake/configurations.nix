# Configuration builders for NixOS and Darwin systems
{
  config,
  inputs,
  lib,
  ...
}: let
  nixosModules = config.flake.modules.nixos or {};
  darwinModules = config.flake.modules.darwin or {};
  homeManagerModules = config.flake.modules.homeManager or {};
  profileRegistry = {
    common-nixos = [
      "nix"
      "home"
      "sops"
      "vscode-server"
    ];

    common-shell = [
      "zsh"
      "atuin"
      "oh-my-posh"
      "aliases"
      "direnv"
      "eza"
      "fd"
    ];

    common-dev = [
      "git"
      "dev-tools"
    ];

    hyprland-desktop = [
      "stylix"
      "desktop-base"
      "hyprland"
      "waybar"
      "hyprlock"
      "hypridle"
      "rofi"
      "wezterm"
      "kitty"
      "firefox"
      "desktop-apps"
      "nixos-desktop-apps"
      "pi"
    ];

    laptop-hyprland = [
      "common-nixos"
      "common-shell"
      "common-dev"
      "hyprland-desktop"
      "power-management"
    ];

    darwin-workstation = [
      "nix"
      "home"
      "home-darwin"
      "homebrew"
      "common-shell"
      "common-dev"
      "wezterm"
      "kitty"
      "desktop-apps"
      "pi"
    ];
  };

  expandProfileItems = items:
    lib.concatMap (
      item:
        if builtins.hasAttr item profileRegistry
        then expandProfileItems (builtins.getAttr item profileRegistry)
        else [item]
    )
    items;

  expandModuleNames = profileNames: moduleNames:
    lib.unique ((expandProfileItems profileNames) ++ moduleNames);

  requireModule = namespace: name:
    if builtins.hasAttr name namespace
    then builtins.getAttr name namespace
    else throw "Missing flake module '${name}'";

  modulesFrom = namespace: moduleNames:
    builtins.map (name: builtins.getAttr name namespace) (
      builtins.filter (name: builtins.hasAttr name namespace) moduleNames
    );

  ensureNixosModule = name:
    if builtins.hasAttr name nixosModules || builtins.hasAttr name homeManagerModules
    then name
    else throw "Requested NixOS module '${name}' was not found in flake.modules.nixos or flake.modules.homeManager";

  ensureDarwinModule = name:
    if builtins.hasAttr name darwinModules || builtins.hasAttr name homeManagerModules
    then name
    else throw "Requested Darwin module '${name}' was not found in flake.modules.darwin or flake.modules.homeManager";

  # Load both NixOS and home-manager modules for a given list of module names
  loadNixosAndHmModules = modules: user: let
    moduleNames = builtins.map ensureNixosModule modules;
  in
    modulesFrom nixosModules moduleNames
    ++ [
      {
        imports = [inputs.home-manager.nixosModules.home-manager];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-backup";
          extraSpecialArgs = {inherit inputs;};
          users.${user}.imports =
            modulesFrom homeManagerModules moduleNames;
        };
      }
    ];

  # Load Darwin modules with home-manager integration
  loadDarwinAndHmModules = modules: user: let
    moduleNames = builtins.map ensureDarwinModule modules;
  in
    modulesFrom darwinModules moduleNames
    ++ [
      {
        imports = [inputs.home-manager.darwinModules.home-manager];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-backup";
          extraSpecialArgs = {inherit inputs;};
          users.${user}.imports =
            modulesFrom homeManagerModules moduleNames;
        };
      }
    ];

  # Create a NixOS system configuration
  mkNixosSystem = {
    hostname,
    system ? "x86_64-linux",
    profiles ? [],
    modules ? [],
    user ? "job",
    extraModules ? [],
  }: let
    moduleNames = expandModuleNames profiles modules;
  in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
        username = user;
      };
      modules =
        [
          # Always include base modules
          (requireModule nixosModules "base")
          # Host-specific module
          (requireModule nixosModules "hosts/${hostname}")
        ]
        ++ (loadNixosAndHmModules moduleNames user)
        ++ extraModules;
    };

  # Create a Darwin system configuration
  mkDarwinSystem = {
    hostname,
    system,
    profiles ? [],
    modules ? [],
    user,
    extraModules ? [],
  }: let
    moduleNames = expandModuleNames profiles modules;
  in
    inputs.darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
        username = user;
      };
      modules =
        [
          # Always include base darwin module
          (requireModule darwinModules "base")
          # Host-specific module
          (requireModule darwinModules "hosts/${hostname}")
        ]
        ++ (loadDarwinAndHmModules moduleNames user)
        ++ extraModules;
    };
in {
  flake.profiles = profileRegistry;

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
      profiles = [
        "common-nixos"
        "common-shell"
        "common-dev"
        "hyprland-desktop"
      ];
      modules = [
        "user-job"
        "power-management"
        "homelab"
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
      profiles = [
        "laptop-hyprland"
      ];
      modules = [
        "user-job"
        "affinity"
        "nixos/networking/azure-vpn"
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
      profiles = [
        "common-nixos"
        "common-shell"
        "common-dev"
      ];
      modules = [
        "user-sooph"
        "wezterm"
        "firefox"
        "desktop-apps"
        "nixos-desktop-apps"
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
      profiles = [
        "darwin-workstation"
      ];
      modules = [
        "user-job"
      ];
    };

    # Work MacBook (Apple Silicon)
    macbook-silicon = mkDarwinSystem {
      hostname = "macbook-silicon";
      system = "aarch64-darwin";
      user = "job.visser";
      profiles = [
        "darwin-workstation"
      ];
      modules = [
        "user-job-work"
      ];
    };
  };
}
