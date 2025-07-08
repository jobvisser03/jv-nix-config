{
  description = "Hopefully this flake will become the flake for all my devices?";

  nixConfig = {
    extra-substituters = [
      "https://cache.soopy.moe"
    ];
    extra-trusted-public-keys = ["cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo="];
  };

  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      # url = "github:nix-community/home-manager/release-25.05";
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    stylix = {
      # url = "github:danth/stylix/release-25.05";
      url = "github:danth/stylix/master";

      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # Firefox addons flake
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    darwin,
    home-manager,
    nixpkgs,
    nixos-hardware,
    hyprland,
    stylix,
    ...
  } @ inputs: {
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
      specialArgs = {inherit inputs;}; # this is for hyprland
      modules = [
        inputs.stylix.nixosModules.stylix
        ./hosts/mac-intel-nixos-host/configuration.nix
        ./hosts/mac-intel-nixos-host/nix/substituter.nix
        nixos-hardware.nixosModules.apple-t2
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = false;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {inherit inputs;};
          home-manager.users.job.imports = [./home/shared-home.nix ./home/home-nixos.nix];
          home-manager.backupFileExtension = "hm-backup";
        }
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
            home.username = "job.visser";
            home.homeDirectory = "/Users/job.visser";
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
            home.username = "job";
            home.homeDirectory = "/Users/job";
          }
        ];
        extraSpecialArgs = {inherit inputs;};
      };
      # NixOS Intel Mac - not used bcoz home-manager is in nixosConfigurations
      # "mac-intel-nixos-hm" = home-manager.lib.homeManagerConfiguration {
      #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
      #   modules = [
      #     # If you want to use home-manager standalon
      #     stylix.homeModules.stylix
      #     ./home/shared-home.nix
      #     ./home/home-nixos.nix
      #     {
      #       home.username = "job";
      #       home.homeDirectory = "/home/job";
      #     }
      #   ];
      # };
      "linux-hm" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        modules = [
          ./home/shared-home.nix
          {
            home.username = "jvisser";
            home.homeDirectory = "/home/jvisser";
          }
        ];
        extraSpecialArgs = {inherit inputs;};
      };
    };
  };
}
