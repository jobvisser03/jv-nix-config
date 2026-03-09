# User definition for "job" - personal use
# Defines NixOS user account and home-manager profile
{
  lib,
  pkgs,
  ...
}: {
  flake.modules = {
    # NixOS user definition
    nixos.user-job = {
      config,
      pkgs,
      lib,
      ...
    }: {
      users.users.job = {
        isNormalUser = true;
        description = "Job Visser";
        extraGroups = ["wheel" "video" "audio" "networkmanager" "docker"];
        shell = pkgs.zsh;
      };

      # Enable zsh for the user
      programs.zsh.enable = true;
    };

    # Darwin user definition
    darwin.user-job = {
      config,
      pkgs,
      lib,
      ...
    }: {
      users.users.job = {
        home = "/Users/job";
        shell = pkgs.zsh;
      };

      # Set this user as the primary user for nix-darwin
      system.primaryUser = "job";

      # Enable zsh
      programs.zsh.enable = true;
    };

    # Home-manager configuration for job
    homeManager.user-job = {
      pkgs,
      lib,
      config,
      ...
    }: {
      home = {
        username = "job";
        homeDirectory =
          if pkgs.stdenv.isDarwin
          then "/Users/job"
          else "/home/job";

        # State version - should match system stateVersion
        stateVersion = "25.11";
      };

      # Enable home-manager itself
      programs.home-manager = {
        enable = true;
      };
    };
  };
}
