# Hyprlock screen lock configuration
{lib, ...}: {
  flake.modules.home.hyprlock = {
    config,
    pkgs,
    ...
  }: {
    programs.hyprlock = {
      enable = true;
    };
  };
}
