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
      modules = [./darwin/system-x86_64-darwin.nix];
    };
    darwinConfigurations."Macbook-FNVDGV37HY" = darwin.lib.darwinSystem {
      modules = [./darwin/system-aarch64-darwin.nix];
    };

    homeConfigurations = {
      # Work Macbook running Apple Silicon
      "job-mac-apple-silicon" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [
          ./shared/home.nix
          {
            home.username = "job.visser";
            home.homeDirectory = "/Users/job.visser";
          }
        ];
      };
      # Personal Macbook running Intel
      "job-mac-intel" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-darwin;
        modules = [
          ./shared/home.nix
          {
            home.username = "job";
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
