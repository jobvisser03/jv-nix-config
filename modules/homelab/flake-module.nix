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
      (import ./_options.nix)
      # Services infrastructure (Caddy, Podman)
      (import ./_services/infrastructure.nix)
      # Individual services
      (import ./_services/cloudflare-ddns.nix)
      (import ./_services/forgejo.nix)
      (import ./_services/gitlab.nix)
      (import ./_services/gitlab-runner.nix)
      (import ./_services/homepage.nix)
      (import ./_services/homeassistant.nix)
      (import ./_services/immich.nix)
      (import ./_services/jellyfin.nix)
      (import ./_services/paperless.nix)
      (import ./_services/radicale.nix)
      (import ./_services/spotify-player.nix)
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
