# Larkbox homelab server host definition
# NixOS server with homelab services
{...}: {
  flake.modules.nixos."hosts/larkbox" = {
    config,
    pkgs,
    lib,
    inputs,
    username,
    ...
  }: {
    imports = [
      # Hardware configuration
      ./_hardware-configuration.nix
      ./_secrets.nix

      # Rclone module
      ../../_rclone
    ];

    # Host identity
    networking.hostName = "larkbox";

    # Enable sudo for wheel group members
    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    # Boot configuration
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Firewall configuration - allow local network and Tailscale
    networking.firewall = {
      enable = true;
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = [41641];
    };

    # Tailscale VPN - enable server routing features for homelab
    services.tailscale.useRoutingFeatures = "server";

    # Desktop mode power management
    powerManagement.desktopMode = true;
    hardware.graphics.enable = true;

    # Homelab services
    homelab = {
      enable = true;
      services.enable = true;
      services.enableReverseProxy = true;
      services.enablePublicHttps = true;

      domain = "dutchdataworks.nl";

      services.forgejo.enable = true;
      services.gitlab.enable = false;
      services.gitlab-runner.enable = false;

      services.immich = {
        enable = true;
        externalLibraryDirs = [
          "/mnt/usb-drive/PHOTOS-PCLOUD"
          "/mnt/usb-drive/SMARTPHONE-PHOTOS-PCLOUD"
        ];
      };

      services.homepage.enable = true;

      services.radicale = {
        enable = false;
        passwordFile = config.sops.secrets.radicale_htpasswd.path;
      };

      services.paperless = {
        enable = true;
        passwordFile = config.sops.secrets.paperless_admin_password.path;
      };

      services.homeassistant = {
        enable = true;
        zigbee2mqtt = {
          enable = true;
          usbDevice = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_34bde4cea845ed1184b8d18f0a86e0b4-if00-port0";
        };
        mosquitto.enable = true;
      };

      services.spotify-player = {
        enable = true;
        clientId = null;
        credentialsFile = config.sops.secrets.spotify_credentials.path;
      };

      services.cloudflare-ddns = {
        enable = true;
        zoneId = "8d43a62314697fa92a98e8b77e771434";
        recordName = "homelab.dutchdataworks.nl";
        tokenFile = config.sops.secrets.cloudflare_ddns_token.path;
      };
    };

    # Rclone cloud storage mounts
    services.rclone = {
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
        pcloud-smartphone-photos = {
          remote = "pcloud:'Automatic Upload'";
          mountpoint = "/mnt/usb-drive/SMARTPHONE-PHOTOS-PCLOUD";
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

    environment.systemPackages = with pkgs; [
      apacheHttpd
    ];

    system.stateVersion = "25.11";
  };
}
