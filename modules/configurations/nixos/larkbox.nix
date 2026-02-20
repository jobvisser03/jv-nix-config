# Larkbox homelab server configuration
{
  inputs,
  config,
  lib,
  ...
}: {
  flake.nixosConfigurations.larkbox = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs;
      username = config.my.users.personal.username;
    };
    modules = [
      # External modules
      inputs.sops-nix.nixosModules.sops
      inputs.stylix.nixosModules.stylix
      inputs.nixos-hardware.nixosModules.aoostar-r1-n100
      inputs.home-manager.nixosModules.home-manager

      # Our deferred modules
      config.flake.modules.nixos.common
      config.flake.modules.nixos.nix-settings
      config.flake.modules.profiles.stylix
      config.flake.modules.sops.base

      # Homelab modules
      config.flake.modules.homelab.options
      config.flake.modules.homelab.services-base
      config.flake.modules.homelab.immich
      config.flake.modules.homelab.homepage

      # Host-specific configuration
      ({
        pkgs,
        username,
        ...
      }: {
        imports = [
          # Hardware configuration (keep in old location for now)
          ../../../../hosts/linux-larkbox-host/hardware-configuration.nix
          # Secrets configuration
          ../../../../hosts/linux-larkbox-host/secrets.nix
          # Import remaining homelab services from legacy location
          ../../../../modules/_legacy/paperless-ngx
          ../../../../modules/_legacy/homeassistant
          ../../../../modules/_legacy/rclone
          ../../../../modules/_legacy/spotify-player
        ];

        networking.hostName = "larkbox";

        boot.loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };

        security.sudo = {
          enable = true;
          wheelNeedsPassword = true;
        };

        networking.firewall = {
          enable = true;
          trustedInterfaces = ["tailscale0"];
          allowedUDPPorts = [41641];
        };

        services.tailscale.useRoutingFeatures = "server";
        powerManagement.desktopMode = true;
        hardware.graphics.enable = true;

        # Homelab service configuration
        homelab = {
          enable = true;
          services = {
            enable = true;
            enableReverseProxy = true;

            immich = {
              enable = true;
              externalLibraryDirs = [
                "/mnt/usb-drive/PHOTOS-PCLOUD"
              ];
            };

            homepage.enable = true;

            paperless = {
              enable = true;
              passwordFile = config.sops.secrets.paperless_admin_password.path;
            };

            homeassistant = {
              enable = true;
              zigbee2mqtt = {
                enable = true;
                usbDevice = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_34bde4cea845ed1184b8d18f0a86e0b4-if00-port0";
              };
              mosquitto.enable = true;
            };

            rclone = {
              enable = true;
              configFile = config.sops.secrets.rclone_config.path;
              mounts = {
                pcloud-photos = {
                  remote = "pcloud:PHOTOS";
                  mountpoint = "/mnt/usb-drive/PHOTOS-PCLOUD";
                  cacheMode = "minimal";
                  readOnly = true;
                  requiredMounts = ["/mnt/usb-drive"];
                };
                pcloud-keepass = {
                  remote = "pcloud:keepass-vault";
                  mountpoint = "/home/${username}/pcloud/keepass-vault";
                  cacheMode = "writes";
                  readOnly = false;
                  uid = 1000;
                  gid = 100;
                };
              };
            };

            spotify-player = {
              enable = true;
              credentialsFile = config.sops.secrets.spotify_credentials.path;
            };
          };
        };

        environment.systemPackages = with pkgs; [
          apacheHttpd
        ];

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
