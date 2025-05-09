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
    darwinConfigurations."mac-intel-host" = darwin.lib.darwinSystem {
      modules = [
        ./hosts/common/system.nix
        ./hosts/mac-intel-host/system.nix
      ];
    };
    darwinConfigurations."mac-apple-silicon-host" = darwin.lib.darwinSystem {
      modules = [
        ./hosts/common/system.nix
        ./hosts/mac-apple-silicon-host/system.nix
      ];
    };

    homeConfigurations = {
      # Work Macbook running Apple Silicon
      "mac-apple-silicon-hm" = home-manager.lib.homeManagerConfiguration {
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
      "mac-intel-hm" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-darwin;
        modules = [
          ./shared/home.nix
          {
            home.username = "job";
            home.homeDirectory = "/Users/job";
          }
        ];
      };
      "linux-hm" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        modules = [
          ./shared/home.nix
          {
            home.username = "jvisser";
            home.homeDirectory = "/home/jvisser";
          }
        ];
      };
    };
  };
}
