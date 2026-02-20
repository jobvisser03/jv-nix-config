# Initialize the flake.modules structure with proper types for deferred modules
{lib, ...}: {
  options.flake.modules = {
    nixos = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = {};
      description = "NixOS deferred modules";
    };
    darwin = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = {};
      description = "Darwin deferred modules";
    };
    home = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = {};
      description = "Home-manager deferred modules";
    };
    homelab = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = {};
      description = "Homelab deferred modules (NixOS)";
    };
    profiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = {};
      description = "Profile deferred modules";
    };
    sops = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = {};
      description = "Sops deferred modules";
    };
  };
}
