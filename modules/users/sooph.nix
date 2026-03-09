# User definition for "sooph" - personal use
# Defines NixOS user account and home-manager profile
{
  lib,
  pkgs,
  ...
}: {
  flake.modules = {
    # NixOS user definition
    nixos.user-sooph = {
      config,
      pkgs,
      lib,
      ...
    }: {
      users.users.sooph = {
        isNormalUser = true;
        description = "DeSooph";
        extraGroups = ["wheel" "video" "audio" "networkmanager" "docker"];
        shell = pkgs.zsh;
      };

      # Enable zsh for the user
      programs.zsh.enable = true;
    };

    # Home-manager configuration for sooph
    homeManager.user-sooph = {
      pkgs,
      lib,
      config,
      ...
    }: {
      home = {
        username = "sooph";
        homeDirectory =
          "/home/sooph";

        # State version - should match system stateVersion
        stateVersion = "25.11";
      };

      # Enable home-manager itself
      programs.home-manager.enable = true;
    };
  };
}
