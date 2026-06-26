# Core flake-parts options and module definitions
# Uses flake-parts.flakeModules.modules for proper deferredModule typing
{
  lib,
  inputs,
  ...
}: {
  imports = [inputs.flake-parts.flakeModules.modules];

  options.flake = {
    # Library functions available to all modules
    lib = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = {};
      description = "Library functions for building configurations";
    };

    # Global metadata
    meta = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.anything;
      default = {};
      description = "Global metadata (users, appearance, programs)";
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {};
      description = "Named module/profile lists used to compose hosts";
    };
  };
}
