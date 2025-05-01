{
  description = "Hopefully this flake will become the flake for all my devices?";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    darwin,
    home-manager,
    nixpkgs,
    ...
  }: {
    darwinConfigurations."Job-MacBook-Pro" = darwin.lib.darwinSystem {
      modules = [./darwin/system.nix];
    };

    homeConfigurations = {
      "job-darwin" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-darwin;
        modules = [
          ./shared/home.nix
          {
            home.homeDirectory = "/Users/job";
          }
        ];
      };
      "job-linux" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./shared/home.nix
          {
            home.homeDirectory = "/home/job";
          }
        ];
      };
    };
  };
}
