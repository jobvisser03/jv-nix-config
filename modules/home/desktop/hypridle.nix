# Hypridle idle daemon configuration
{lib, ...}: {
  flake.modules.home.hypridle = {
    config,
    pkgs,
    ...
  }: {
    services.hypridle = {
      enable = true;
    };
  };
}
