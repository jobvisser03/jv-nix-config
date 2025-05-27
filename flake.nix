{
  description = "Hopefully this flake will become the flake for all my devices?";

  nixConfig = {
    extra-substituters = [
      "https://cache.soopy.moe"
    ];
    extra-trusted-public-keys = [ "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = {
    darwin,
    home-manager,
    nixpkgs,
    nixos-hardware,
    ...
  }: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

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

    nixosConfigurations.mac-intel-nixos-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; }; # this is for hyprland
      modules = [
        ./hosts/mac-intel-nixos-host/configuration.nix
        ./hosts/mac-intel-nixos-host/nix/substituter.nix
        nixos-hardware.nixosModules.apple-t2
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
      # NixOS Intel Mac
      "mac-intel-nixos-hm" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./shared/home.nix
          {
            home.username = "job";
            home.homeDirectory = "/home/job";
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
