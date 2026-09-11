# Nixpkgs overlays
{inputs, ...}: {
  flake.overlays = {
    # Custom modifications to packages
    modifications = final: prev: {
      # Add any package overrides here
    };

    # Exposes the unstable nixpkgs tree as `pkgs.unstable.<pkg>`.
    # Use for dev tools/apps that should move faster than the stable base
    # (e.g. `pkgs.unstable.devenv`), without unpinning the whole system.
    unstable-packages = final: _prev: {
      unstable = import inputs.nixpkgs-unstable {
        inherit (final.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    };
  };

  # Apply overlays to perSystem
  perSystem = {system, ...}: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        inputs.nix4vscode.overlays.default
        inputs.self.overlays.unstable-packages
        # inputs.self.overlays.modifications
      ];
    };
  };
}
