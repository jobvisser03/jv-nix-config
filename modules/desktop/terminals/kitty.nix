# Kitty terminal configuration
# Home-manager only module
{...}: {
  flake.modules.homeManager.kitty = {
    pkgs,
    lib,
    config,
    ...
  }: {
    programs.kitty.enable = true;
  };
}
