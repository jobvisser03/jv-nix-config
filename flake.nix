{
  description = "Master flake for all devices - dendritic flake-parts structure";

  nixConfig = {
    extra-substituters = [
      "https://jv-nix-config-cache.cachix.org"
      "https://cache.nixos.org"
      "https://pi.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "jv-nix-config-cache.cachix.org-1:pvYeur0OqEar9g5x6mETEsrJSoW+U7eE7BbA4bB925w="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    # Stable for host laptops and servers (and anything else that wants stability)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Rolling pool for dev tools that want to move faster than the stable base
    # (exposed as `pkgs.unstable.<pkg>` via modules/flake/overlays.nix)
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager package pool (rolling, devenv-patched)
    nixpkgs-devenv.url = "github:cachix/devenv-nixpkgs/rolling";

    # Pinned to release-26.05 to match the stable nixpkgs base — avoids
    # OS-level module/option drift between HM and the system it configures.
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pinned to release-26.05 (stylix master is rolling and expects inputs in lockstep)
    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr.url = "github:ogulcancelik/herdr/v0.9.0";

    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs-devenv";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };

    import-tree.url = "github:vic/import-tree";

    handy = {
      url = "github:cjpais/Handy";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    affinity-nix = {
      url = "github:mrshmllow/affinity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi.url = "github:lukasl-dev/pi.nix";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
}
