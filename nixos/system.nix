{
  pkgs,
  lib,
  ...
}: {
  # This is needed for home-manager to work
  users.users.simon = {home = "/home/simon";};

  # add nix stuff to /etc/zshrc
  programs.zsh.enable = true;

  nix = {
    # update nix to the latest version
    package = pkgs.nix;

    # clean the nix store
    gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 7d";
    };

    settings = {
      # Necessary for using flakes on this system.
      experimental-features = ["nix-command" "flakes"];

      # Cachix is apparently a cache that most people use, but putting it here does not seem to do a lot
      substituters = ["https://nix-community.cachix.org"];
      trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
      builders-use-substitutes = true;
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
