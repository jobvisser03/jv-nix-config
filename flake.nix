{
  description = "Master flake for all devices";

  nixConfig = {
    extra-substituters = [
      "https://jv-nix-config-cache.cachix.org"
      "https://cache.soopy.moe"
      "https://cache.nixos.org"
    ];
    extra-trusted-public-keys = [
      "jv-nix-config-cache.cachix.org-1:pvYeur0OqEar9g5x6mETEsrJSoW+U7eE7BbA4bB925w="
      "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    stylix = {
      url = "github:danth/stylix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    darwin,
    home-manager,
    nixpkgs,
    nixos-hardware,
    stylix,
    ...
  } @ inputs: let
    # Centralized user configuration
    users = {
      personal = {
        username = "job";
        homeDirectory = {
          linux = "/home/job";
          darwin = "/Users/job";
        };
      };
      work = {
        username = "job.visser";
        homeDirectory = {
          darwin = "/Users/job.visser";
        };
      };
    };
  in {
    formatter = {
      x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
      aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
      x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin.alejandra;
    };

    darwinConfigurations."mac-intel-host" = darwin.lib.darwinSystem {
      specialArgs = {
        inherit inputs;
        username = users.personal.username;
      };
      modules = [
        ./hosts/common/darwin
        ./hosts/mac-intel-host/system.nix
      ];
    };

    darwinConfigurations."mac-apple-silicon-host" = darwin.lib.darwinSystem {
      specialArgs = {
        inherit inputs;
        username = users.work.username;
      };
      modules = [
        ./hosts/common/darwin
        ./hosts/mac-apple-silicon-host/system.nix
      ];
    };

    nixosConfigurations.mac-intel-nixos-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        username = users.personal.username;
      };
      modules = [
        inputs.stylix.nixosModules.stylix
        ./hosts/mac-intel-nixos-host/configuration.nix
        nixos-hardware.nixosModules.apple-t2
        inputs.home-manager.nixosModules.home-manager
        ({config, ...}: {
          home-manager.useGlobalPkgs = false;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {inherit inputs;};
          home-manager.users.${users.personal.username}.imports = [./home/shared-home.nix ./home/home-nixos.nix];
          home-manager.backupFileExtension = "hm-backup";
        })
      ];
    };

    nixosConfigurations.linux-larkbox-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        username = users.personal.username;
      };
      modules = [
        inputs.sops-nix.nixosModules.sops
        inputs.stylix.nixosModules.stylix
        ./hosts/linux-larkbox-host/configuration.nix
        nixos-hardware.nixosModules.aoostar-r1-n100
        inputs.home-manager.nixosModules.home-manager
        ({config, ...}: {
          home-manager.useGlobalPkgs = false;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {inherit inputs;};
          home-manager.users.${users.personal.username}.imports = [
            ./home/shared-home.nix
            ./home/home-nixos.nix
            ./hosts/linux-larkbox-host/home.nix
          ];
          home-manager.backupFileExtension = "hm-backup";
        })
      ];
    };

    homeConfigurations = {
      # Work Macbook running Apple Silicon
      "mac-apple-silicon-hm" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [
          ./home/shared-home.nix
          ./home/home-mac.nix
          {
            home.username = users.work.username;
            home.homeDirectory = users.work.homeDirectory.darwin;
          }
        ];
        extraSpecialArgs = {inherit inputs;};
      };
      # Personal Macbook running Intel
      "mac-intel-hm" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-darwin;
        modules = [
          ./home/shared-home.nix
          ./home/home-mac.nix
          {
            home.username = users.personal.username;
            home.homeDirectory = users.personal.homeDirectory.darwin;
          }
        ];
        extraSpecialArgs = {inherit inputs;};
      };
    };
  };
}
