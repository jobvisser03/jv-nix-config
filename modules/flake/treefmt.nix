# Treefmt configuration for code formatting
{inputs, ...}: {
  imports = [inputs.treefmt-nix.flakeModule];

  perSystem = {pkgs, ...}: {
    treefmt = {
      projectRootFile = "flake.nix";

      programs = {
        # Nix formatting
        alejandra.enable = true;

        # Shell formatting
        shfmt.enable = true;

        # YAML/JSON formatting
        prettier = {
          enable = true;
          includes = [
            "*.json"
            "*.yaml"
            "*.yml"
          ];
        };
      };
    };
  };
}
