{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    # Hardware configuration (you'll need to generate this)
    ./hardware-configuration.nix

    # Common system modules
    ../../modules/system

    # Profiles
    ../../profiles/default.nix

    # Secret management (sops-nix)
    ../../modules/sops
    ./secrets.nix

    # Homelab services
    ../../modules/homelab
  ];

  # Host-specific configuration
  networking.hostName = "larkbox";

  # Time zone
  time.timeZone = "Europe/Amsterdam";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";

  # Boot configuration (adjust for your setup)
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Network configuration
  networking.networkmanager.enable = true;

  # Enable Avahi for mDNS (makes larkbox.local resolvable on local network)
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Enable mDNS resolution for IPv4
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # Define user account specific to this host
  users.users.job = {
    isNormalUser = true;
    extraGroups = ["wheel" "video" "audio" "networkmanager"];
    packages = with pkgs; [
      tree
    ];
    shell = pkgs.zsh;
  };

  services.openssh.enable = true;
  networking.firewall.enable = false;

  # VS Code Remote SSH support (nix-ld with required libraries)
  programs.vscodeRemoteSSH.enable = true;

  # Enable Hyprland at NixOS level (makes hyprctl, start-hyprland available in PATH)
  programs.hyprland.enable = true;

  # Host-specific greetd initial session
  # Use start-hyprland wrapper instead of direct Hyprland binary
  # (avoids "use start-hyprland instead" warning)
  services.greetd.settings.initial_session = {
    command = "${pkgs.hyprland}/bin/start-hyprland";
    user = "job";
  };

  # Desktop mode - always plugged in (no TLP battery management)
  powerManagement.desktopMode = true;

  # Enable Intel graphics hardware acceleration (for Immich ML, video transcoding)
  hardware.graphics.enable = true;

  # ============================================
  # Homelab Configuration
  # ============================================
  homelab = {
    enable = true;

    # Services infrastructure
    services.enable = true;
    services.enableReverseProxy = false; # Direct port access for now

    # Individual services
    services.immich = {
      enable = true;
      # mediaDir defaults to /var/lib/immich (Immich internal storage)
      # External library for pCloud photos (configured in Immich UI after deployment)
      externalLibraryDirs = [
        "/mnt/usb-drive/PHOTOS-PCLOUD"
        "/mnt/usb-drive/SMARTPHONE-PHOTOS-PCLOUD"
      ];
    };
    services.jellyfin.enable = false;
    services.homepage.enable = true;
    # services.homepage.jellyfin.apiKeyFile = config.sops.secrets.jellyfin_api_key.path;
    services.radicale.enable = false;
    services.radicale.passwordFile = config.sops.secrets.radicale_htpasswd.path;
    services.homeassistant = {
      enable = true;
      # Zigbee2MQTT for Sonoff Zigbee 3.0 USB Dongle Plus
      zigbee2mqtt = {
        enable = true;
        usbDevice = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_34bde4cea845ed1184b8d18f0a86e0b4-if00-port0";
      };
      # Mosquitto MQTT broker for Home Assistant <-> Zigbee2MQTT communication
      mosquitto.enable = true;
    };

    # Rclone pCloud mounts
    services.rclone = {
      enable = true;
      configFile = config.sops.secrets.rclone_config.path;
      mounts = {
        # pCloud photos for Immich external library (read-only)
        pcloud-photos = {
          remote = "pcloud:PHOTOS";
          mountpoint = "/mnt/usb-drive/PHOTOS-PCLOUD";
          cacheMode = "minimal"; # Read-only access, minimal caching
          readOnly = true; # External library is read-only
          requiredMounts = ["/mnt/usb-drive"]; # Wait for USB drive to be mounted
        };
        # pCloud smartphone photos for Immich external library (read-only)
        pcloud-smartphone-photos = {
          remote = "pcloud:'Automatic Upload'";
          mountpoint = "/mnt/usb-drive/SMARTPHONE-PHOTOS-PCLOUD";
          cacheMode = "minimal"; # Read-only access, minimal caching
          readOnly = true; # External library is read-only
          requiredMounts = ["/mnt/usb-drive"]; # Wait for USB drive to be mounted
        };
        # KeePass vault for password database access
        pcloud-keepass = {
          remote = "pcloud:keepass-vault";
          mountpoint = "/home/job/pcloud/keepass-vault";
          cacheMode = "writes";
          readOnly = false; # Allow writes for KeePass sync
          uid = 1000; # job user
          gid = 100; # users group
        };
      };
    };
  };

  # System packages specific to this host
  environment.systemPackages = with pkgs; [
    # Homelab utilities
    apacheHttpd # Provides htpasswd for creating Radicale passwords
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "25.11";
}
