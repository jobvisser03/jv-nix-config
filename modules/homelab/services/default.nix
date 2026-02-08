# Services module - Caddy reverse proxy and Podman setup
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab;
in {
  options.homelab.services = {
    enable = lib.mkEnableOption "Enable homelab services infrastructure (Caddy, Podman)";

    enableReverseProxy = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Caddy as reverse proxy for services";
    };
  };

  imports = [
    ./gitlab
    ./immich
    ./jellyfin
    ./homepage
    ./radicale
    ./homeassistant
    ./rclone
  ];

  config = lib.mkIf (cfg.enable && cfg.services.enable) {
    # Open firewall for HTTP (local network only, no HTTPS needed)
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.services.enableReverseProxy [80];

    # Caddy reverse proxy (local network, no HTTPS)
    services.caddy = lib.mkIf cfg.services.enableReverseProxy {
      enable = true;
      globalConfig = ''
        # Local network only - no automatic HTTPS
        auto_https off
      '';
    };

    # Podman for OCI containers (Home Assistant, etc.)
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      autoPrune.enable = true;
      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };

    # Use Podman as OCI backend
    virtualisation.oci-containers.backend = "podman";

    # Allow DNS in podman network
    networking.firewall.interfaces.podman0.allowedUDPPorts = [53];
  };
}
