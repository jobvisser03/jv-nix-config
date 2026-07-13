# Nixpkgs overlays
{inputs, ...}: {
  flake.overlays = {
    # Custom modifications to packages
    modifications = final: prev: {
      # Add any package overrides here
    };
  };

  # Apply overlays to perSystem
  perSystem = {system, ...}: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        inputs.nix4vscode.overlays.default
        # inputs.self.overlays.modifications
      ];
    };
  };
}
