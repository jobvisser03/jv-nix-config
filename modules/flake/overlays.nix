# Nixpkgs overlays
{inputs, ...}: {
  flake.overlays = {
    # Add stable packages as pkgs.stable.*
    stable-packages = final: _prev: {
      stable = import inputs.nixpkgs-stable {
        inherit (final) system;
        config.allowUnfree = true;
      };
    };

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
        # inputs.self.overlays.stable-packages
        # inputs.self.overlays.modifications
      ];
    };
  };
}
