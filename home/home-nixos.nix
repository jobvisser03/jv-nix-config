{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  imports = [
    ../modules/wm/hyprland.nix
    ../modules/wm/waybar.nix
    ../modules/wm/hyprlock.nix
    ../modules/wm/hypridle.nix
    ../modules/home-manager/rofi.nix
  ];

  home.packages = with pkgs; [
    keepassxc
    drawio
    anki-bin
    docker-client
    overskride
    nautilus
    sops
  ];

  stylix.enable = true;
  stylix.polarity = "dark";
  stylix.targets.firefox.profileNames = ["default"];
  stylix.targets.vscode.enable = false;

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };
}
