# Core flake-parts options and module definitions
{
  lib,
  inputs,
  ...
}: let
  # Type for a collection of modules (name -> module function)
  moduleSetType = lib.types.attrsOf lib.types.unspecified;
in {
  # Define custom flake options
  options.flake = {
    # Library functions available to all modules
    lib = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = {};
      description = "Library functions for building configurations";
    };

    # Module definitions - NixOS and home-manager
    modules = {
      nixos = lib.mkOption {
        type = moduleSetType;
        default = {};
        description = "NixOS modules that can be composed into configurations";
      };
      homeManager = lib.mkOption {
        type = moduleSetType;
        default = {};
        description = "Home-manager modules that can be composed into configurations";
      };
      darwin = lib.mkOption {
        type = moduleSetType;
        default = {};
        description = "Darwin modules that can be composed into configurations";
      };
    };

    # Global metadata
    meta = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = {};
      description = "Global metadata (users, appearance, programs)";
    };
  };
}
