# User definition for "job.visser" - work use (Apple Silicon Mac)
# Defines Darwin user account and home-manager profile
{
  lib,
  pkgs,
  ...
}: {
  flake.modules = {
    # Darwin user definition for work
    darwin.user-job-work = {
      config,
      pkgs,
      lib,
      ...
    }: {
      users.users."job.visser" = {
        home = "/Users/job.visser";
        shell = pkgs.zsh;
      };

      # Set this user as the primary user for nix-darwin
      system.primaryUser = "job.visser";

      # Enable zsh
      programs.zsh.enable = true;
    };

    # Home-manager configuration for job.visser (work)
    homeManager.user-job-work = {
      pkgs,
      lib,
      config,
      ...
    }: {
      home = {
        username = "job.visser";
        homeDirectory = "/Users/job.visser";

        # State version - should match system stateVersion
        stateVersion = "25.11";
      };

      # Enable home-manager itself
      programs.home-manager.enable = true;
    };
  };
}
