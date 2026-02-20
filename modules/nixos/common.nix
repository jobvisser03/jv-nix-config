# Base NixOS configuration - applies to all NixOS hosts
{lib, ...}: {
  flake.modules.nixos.common = {
    config,
    pkgs,
    ...
  }: {
    time.timeZone = lib.mkDefault "Europe/Amsterdam";
    i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

    networking.networkmanager.enable = lib.mkDefault true;

    services.avahi = {
      enable = lib.mkDefault true;
      nssmdns4 = lib.mkDefault true;
      publish = {
        enable = lib.mkDefault true;
        addresses = lib.mkDefault true;
        workstation = lib.mkDefault true;
      };
    };

    services.openssh.enable = lib.mkDefault true;
    programs.vscodeRemoteSSH.enable = lib.mkDefault true;

    services.tailscale = {
      enable = lib.mkDefault true;
      useRoutingFeatures = lib.mkDefault "client";
    };

    programs.zsh.enable = true;

    system.stateVersion = lib.mkDefault "25.11";
  };
}
