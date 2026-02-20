# NixOS on Intel Mac - Desktop configuration
{
  inputs,
  config,
  lib,
  ...
}: {
  flake.nixosConfigurations.mac-intel-nixos-host = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs;
      username = config.my.users.personal.username;
    };
    modules = [
      # External modules
      inputs.stylix.nixosModules.stylix
      inputs.nixos-hardware.nixosModules.apple-t2
      inputs.home-manager.nixosModules.home-manager

      # Our deferred modules
      config.flake.modules.nixos.common
      config.flake.modules.nixos.nix-settings
      config.flake.modules.nixos.hyprland
      config.flake.modules.nixos.greetd
      config.flake.modules.nixos.audio
      config.flake.modules.nixos.bluetooth
      config.flake.modules.profiles.desktop
      config.flake.modules.profiles.stylix

      # Host-specific configuration
      ({
        pkgs,
        username,
        ...
      }: {
        imports = [
          # Hardware configuration (keep in old location for now)
          ../../../../hosts/mac-intel-nixos-host/hardware-configuration.nix
        ];

        networking.hostName = "mac-intel-nixos";

        boot.loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };

        # AMD GPU driver
        services.xserver.videoDrivers = ["amdgpu"];

        # Home-manager integration
        home-manager = {
          useGlobalPkgs = false;
          useUserPackages = true;
          extraSpecialArgs = {inherit inputs;};
          users.${username} = {
            imports = [
              config.flake.modules.home.common
              config.flake.modules.home.packages
              config.flake.modules.home.zsh
              config.flake.modules.home.shell-tools
              config.flake.modules.home.dev-tools
              config.flake.modules.home.browser
              config.flake.modules.home.nixos
              config.flake.modules.home.hyprland
              config.flake.modules.home.waybar
              config.flake.modules.home.rofi
              config.flake.modules.home.hyprlock
              config.flake.modules.home.hypridle
            ];
            home.username = username;
            home.homeDirectory = "/home/${username}";
          };
          backupFileExtension = "hm-backup";
        };

        users.users.${username} = {
          isNormalUser = true;
          extraGroups = ["wheel" "video" "audio" "networkmanager"];
          shell = pkgs.zsh;
        };

        system.stateVersion = "25.11";
      })
    ];
  };
}
