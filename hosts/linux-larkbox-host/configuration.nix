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

  # Host-specific greetd initial session
  services.greetd.settings.initial_session = {
    command = "${pkgs.hyprland}/bin/Hyprland";
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

    # Storage paths
    mounts = {
      media = "/media/usb-drive";
      photos = "/media/usb-drive/PICTURES";
    };

    # Services infrastructure
    services.enable = true;

    # Individual services
    services.immich.enable = true;
    services.homepage.enable = true;
    services.radicale.enable = true;
    # services.radicale.passwordFile = "/etc/secrets/radicale-htpasswd";  # Uncomment after creating htpasswd file
    services.homeassistant.enable = true;
  };

  # System packages specific to this host
  environment.systemPackages = with pkgs; [
    # Homelab utilities
    apacheHttpd  # Provides htpasswd for creating Radicale passwords
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "25.11";
}
