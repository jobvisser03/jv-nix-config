{
  description = "Hopefully this flake will become the flake for all my devices?";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    darwin,
    home-manager,
    nixpkgs,
    nixos-wsl,
    ...
  }: {
    # this tells nix-darwin what to build
    darwinConfigurations."Simons-MacBook-Air" = darwin.lib.darwinSystem {
      modules = [
        ./darwin/system.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.users.simon = {
            imports = [
              ./shared/home.nix
              ./darwin/home.nix
            ];
          };
        }
      ];
    };

    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            system.stateVersion = "24.05";
            wsl.enable = true;
            home-manager.users.simon = {
              imports = [
                ./shared/home.nix
              ];
            };
          }
        ];
      };
    };
  };
}
