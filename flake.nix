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
    ...
  }: {
    # this tells nix-darwin what to build
    darwinConfigurations."Simons-MacBook-Air" = darwin.lib.darwinSystem {
      modules = [
        ./system.nix
        home-manager.darwinModules.home-manager
        {home-manager.users.simon = import ./home.nix;}
      ];
    };
  };
}
