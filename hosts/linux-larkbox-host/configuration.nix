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

  # Host-specific greetd initial session
  services.greetd.settings.initial_session = {
    command = "${pkgs.hyprland}/bin/Hyprland";
    user = "job";
  };

  # System packages specific to this host
  environment.systemPackages = with pkgs; [
    # Add larkbox-specific packages here
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "25.05";
}
