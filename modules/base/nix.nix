# Base Nix settings - always included in all NixOS/Darwin configurations
{inputs, ...}: {
  flake.modules = {
    # NixOS nix settings
    nixos.nix = {
      config,
      username,
      ...
    }: {
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        # Allow the configured user to use nix commands
        trusted-users = ["root" username];

        # Enable builders to use substitutes
        builders-use-substitutes = true;

        # Comprehensive list of substituters
        substituters = [
          "https://cache.nixos.org"
          "https://cache.soopy.moe"
          "https://nix-community.cachix.org"
          "https://nixpkgs-unfree.cachix.org"
        ];

        # Mark additional substituters as trusted
        trusted-substituters = [
          "https://cache.soopy.moe"
          "https://nix-community.cachix.org"
          "https://nixpkgs-unfree.cachix.org"
        ];

        # Public keys for all substituters
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
        ];
      };

      nixpkgs.config.allowUnfree = true;
    };

    # Darwin nix settings
    darwin.nix = {username, ...}: {
      # nix-darwin manages nix itself, so we disable it here
      nix.enable = false;

      nixpkgs.config.allowUnfree = true;
    };

    # Home-manager nix settings
    homeManager.nix = {pkgs, ...}: {
      nix.settings.experimental-features = ["nix-command" "flakes"];
      # Note: nixpkgs.config is not set here because we use useGlobalPkgs = true
      # which inherits pkgs from the system configuration
    };
  };
}
