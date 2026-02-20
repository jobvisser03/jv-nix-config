# Hyprland window manager - NixOS system configuration
{lib, ...}: {
  flake.modules.nixos.hyprland = {
    config,
    pkgs,
    ...
  }: {
    programs.hyprland.enable = true;
    programs.hyprlock.enable = true;

    services.hypridle.enable = true;

    # Required for Hyprland
    security.polkit.enable = true;
    hardware.graphics.enable = true;
  };
}
