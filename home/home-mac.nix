{
  pkgs,
  lib,
  config,
  ...
}: {
  # macOS-specific Home Manager options go here
  # Example: macOS-only packages, settings, etc.
  home.packages = with pkgs; [
    # Add macOS-specific packages here
    # e.g. pkgs.mas, pkgs.iterm2
    blueutil
  ];
  # Add more macOS-specific config as needed
  nix.package = pkgs.nix;
}
