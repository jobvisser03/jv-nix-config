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
      "llm-secrets"
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
      "vscode"
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
      "llm-secrets-darwin"
      "homebrew"
      "common-shell"
      "common-dev"
      "wezterm"
      "kitty"
      "firefox"
      "desktop-apps"
      "vscode"
      "omlx"
      "pi"
    ];
  };

  expandProfileItems = items:
    lib.concatMap (
      item:
        if builtins.hasAttr item profileRegistry
        then expandProfileItems (builtins.getAttr item profileRegistry)
        # Pass through leaf names — validated later by ensureNixos/DarwinModule.
        # If a profile name is misspelled it will surface there with a clear error.
        else [item]
    )
    items;

  expandModuleNames = profileNames: moduleNames:
    lib.unique ((expandProfileItems profileNames) ++ moduleNames);

  # Strict single-name lookup — throws if the name is absent.
  requireModule = namespace: name:
    if builtins.hasAttr name namespace
    then builtins.getAttr name namespace
    else throw "Missing flake module '${name}'";

  # Intentional dual-namespace filter: a name may exist in nixosModules,
  # homeManagerModules, or both.  ensureNixos/DarwinModule guarantees that
  # every name is present in at least one namespace before this is called,
  # so silent drops here are expected, not bugs.
  filterModulesFrom = namespace: moduleNames:
    builtins.map (name: builtins.getAttr name namespace) (
      builtins.filter (name: builtins.hasAttr name namespace) moduleNames
    );

  # Partition a mixed list into string names (resolved via namespace lookup)
  # and direct module values (attrsets / functions, passed through as-is).
  # This lets host configs reference flake.modules.nixos.foo directly for
  # IDE traceability while keeping string names for profile-registry items.
  partitionModules = modules: {
    names = builtins.filter builtins.isString modules;
    direct = builtins.filter (m: !builtins.isString m) modules;
  };

  ensureNixosModule = name:
    if builtins.hasAttr name nixosModules || builtins.hasAttr name homeManagerModules
    then name
    else throw "Requested NixOS module '${name}' was not found in flake.modules.nixos or flake.modules.homeManager";

  ensureDarwinModule = name:
    if builtins.hasAttr name darwinModules || builtins.hasAttr name homeManagerModules
    then name
    else throw "Requested Darwin module '${name}' was not found in flake.modules.darwin or flake.modules.homeManager";

  # Load both NixOS and home-manager modules.
  # `modules` may contain string names (looked up in both nixos + HM namespaces)
  # OR direct module values (attrsets / functions, included at the nixos level
  # only — use a string name when you also need HM integration).
  loadNixosAndHmModules = modules: user: let
    parts = partitionModules modules;
    validatedNames = builtins.map ensureNixosModule parts.names;
  in
    filterModulesFrom nixosModules validatedNames
    ++ parts.direct
    ++ [
      {
        imports = [inputs.home-manager.nixosModules.home-manager];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-backup";
          extraSpecialArgs = {inherit inputs;};
          users.${user}.imports =
            filterModulesFrom homeManagerModules validatedNames;
        };
      }
    ];

  # Load Darwin modules with home-manager integration.
  # Accepts the same mixed string / direct-value list as loadNixosAndHmModules.
  loadDarwinAndHmModules = modules: user: let
    parts = partitionModules modules;
    validatedNames = builtins.map ensureDarwinModule parts.names;
  in
    filterModulesFrom darwinModules validatedNames
    ++ parts.direct
    ++ [
      {
        imports = [inputs.home-manager.darwinModules.home-manager];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-backup";
          extraSpecialArgs = {inherit inputs;};
          users.${user}.imports =
            filterModulesFrom homeManagerModules validatedNames;
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
        "vscode"
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
