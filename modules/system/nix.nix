{...}: {
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Common substituters for all systems
    substituters = [
      "https://cache.nixos.org/"
      "https://cache.soopy.moe"
    ];

    trusted-substituters = [
      "https://cache.soopy.moe"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo="
    ];
  };
}
