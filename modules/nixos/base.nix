# Base NixOS configuration
# NixOS only module - system settings and base configuration
{...}: {
  flake.modules.nixos.base = {
    pkgs,
    lib,
    config,
    username,
    ...
  }: {
    # Timezone and locale
    time.timeZone = lib.mkDefault "Europe/Amsterdam";
    i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

    # Networking
    networking.networkmanager.enable = lib.mkDefault true;

    # Avahi for local network discovery
    services.avahi = {
      enable = lib.mkDefault true;
      nssmdns4 = lib.mkDefault true;
      publish = {
        enable = lib.mkDefault true;
        addresses = lib.mkDefault true;
        workstation = lib.mkDefault true;
      };
    };

    # SSH
    services.openssh.enable = lib.mkDefault true;

    # VSCode Remote SSH
    programs.vscodeRemoteSSH.enable = lib.mkDefault true;

    # Tailscale VPN
    services.tailscale = {
      enable = lib.mkDefault true;
      useRoutingFeatures = lib.mkDefault "client";
    };

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Default state version
    system.stateVersion = lib.mkDefault "25.11";
  };
}
