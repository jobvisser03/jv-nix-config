# Homelab flake-parts module
# Wraps all homelab NixOS modules into a single flake.modules.nixos.homelab module
{...}: {
  flake.modules.nixos.homelab = {
    config,
    lib,
    pkgs,
    username,
    ...
  }: let
    cfg = config.homelab;
  in {
    # Import all homelab modules
    imports = [
      # Core homelab options
      (import ./options.nix)
      # Services infrastructure (Caddy, Podman)
      (import ./services/infrastructure.nix)
      # Individual services
      (import ./services/cloudflare-ddns.nix)
      (import ./services/forgejo.nix)
      (import ./services/gitlab.nix)
      (import ./services/gitlab-runner.nix)
      (import ./services/homepage.nix)
      (import ./services/homeassistant.nix)
      (import ./services/immich.nix)
      (import ./services/jellyfin.nix)
      (import ./services/paperless.nix)
      (import ./services/radicale.nix)
      (import ./services/spotify-player.nix)
    ];

    config = lib.mkIf cfg.enable {
      # Create shared user/group for homelab services
      users.groups.${cfg.group} = {};
      users.users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        description = "Homelab services user";
      };
    };
  };
}
