# Common NixOS system configuration
{
  config,
  pkgs,
  lib,
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

  users.users.job = {
    isNormalUser = true;
    extraGroups = ["wheel" "video" "audio" "networkmanager"];
    shell = pkgs.zsh;
  };

  system.stateVersion = lib.mkDefault "25.11";
}
