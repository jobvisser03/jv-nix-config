# Darwin-specific home-manager configuration
{lib, ...}: {
  flake.modules.home.darwin = {
    config,
    pkgs,
    ...
  }: {
    home.packages = with pkgs; [
      blueutil
    ];

    nix.package = pkgs.nix;
  };
}
