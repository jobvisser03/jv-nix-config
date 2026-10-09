# Treefmt configuration for code formatting
{inputs, ...}: {
  imports = [inputs.treefmt-nix.flakeModule];

  perSystem = {pkgs, ...}: {
    treefmt = {
      projectRootFile = "flake.nix";

      # sops-encrypted files: never rewrite (sops owns their layout)
      settings.global.excludes = ["secrets/*.yaml"];

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
