# NixOS-specific home-manager configuration
{lib, ...}: {
  flake.modules.home.nixos = {
    config,
    pkgs,
    ...
  }: {
    home.packages = with pkgs; [
      keepassxc
      drawio
      anki-bin
      docker-client
      overskride
      nautilus
    ];

    stylix.enable = true;
    stylix.polarity = "dark";
    stylix.targets.firefox.profileNames = ["default"];
    stylix.targets.vscode.enable = false;

    programs.vscode = {
      enable = true;
      package = pkgs.vscode.fhs;
    };
  };
}
