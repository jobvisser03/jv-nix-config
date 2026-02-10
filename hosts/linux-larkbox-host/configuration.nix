{
  config,
  pkgs,
  lib,
  inputs,
  username,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../common/nixos
    ../../modules/system
    ../../profiles
    ../../modules/sops
    ./secrets.nix
    ../../modules/homelab
  ];

  networking.hostName = "larkbox";
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.networkmanager.enable = true;

  # Firewall configuration - allow local network and Tailscale
  networking.firewall = {
    enable = true;
    # Trust Tailscale interface - all Tailscale traffic allowed
    trustedInterfaces = ["tailscale0"];
    # Allow Tailscale UDP for connection establishment
    allowedUDPPorts = [41641];
    # Note: HTTP port 80 opened by homelab module when reverse proxy enabled
  };

  # Tailscale VPN - enable server routing features for homelab
  services.tailscale.useRoutingFeatures = "server";

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  services.openssh.enable = true;

  powerManagement.desktopMode = true;
  hardware.graphics.enable = true;

  homelab = {
    enable = true;
    services.enable = true;
    services.enableReverseProxy = true;

    # GitLab - Web-based Git repository management
    services.gitlab.enable = false;

    # GitLab Runner - CI/CD job executor
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

    services.homeassistant = {
      enable = true;
      zigbee2mqtt = {
        enable = true;
        usbDevice = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_34bde4cea845ed1184b8d18f0a86e0b4-if00-port0";
      };
      mosquitto.enable = true;
    };

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
  };

  environment.systemPackages = with pkgs; [
    apacheHttpd
  ];

  system.stateVersion = "25.11";
}
