{config, ...}: {
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Allow job user to use nix commands
    trusted-users = [config.users.users.job.name];

    # Enable builders to use substitutes
    builders-use-substitutes = true;

    # Comprehensive list of substituters
    substituters = [
      "https://cache.nixos.org"
      "https://cache.soopy.moe"
      "https://nix-community.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
      "https://hyprland.cachix.org"
    ];

    # Mark additional substituters as trusted
    trusted-substituters = [
      "https://cache.soopy.moe"
      "https://nix-community.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
      "https://hyprland.cachix.org"
    ];

    # Public keys for all substituters
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };
}
