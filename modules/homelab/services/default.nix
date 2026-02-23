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

    # Enable public HTTPS for external access via Caddy and Let's Encrypt
    enablePublicHttps = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable public HTTPS termination on this host (opens ports 80/443 and lets Caddy obtain certificates)";
    };
  };

  imports = [
    ./cloudflare-ddns
    ./gitlab
    ./gitlab-runner
    ./immich
    ./jellyfin
    ./homepage
    ./radicale
    ./homeassistant
    ./paperless-ngx
    ./rclone
    ./spotify-player
  ];

  config = lib.mkIf (cfg.enable && cfg.services.enable) {
    # Open firewall for HTTP/HTTPS when reverse proxy is enabled
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.services.enableReverseProxy (
      if cfg.services.enablePublicHttps
      then [80 443]
      else [80]
    );

    # Caddy reverse proxy
    services.caddy = lib.mkIf cfg.services.enableReverseProxy {
      enable = true;

      # When public HTTPS is disabled we turn off automatic HTTPS and keep Caddy HTTP-only
      # (for LAN/Tailscale access). When enabled, we let Caddy manage HTTPS with ACME.
      globalConfig = lib.mkIf (!cfg.services.enablePublicHttps) ''
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

    # Create a shared network for homelab containers
    # This allows containers to communicate by name (DNS resolution)
    systemd.services.podman-homelab-network = {
      description = "Create homelab podman network";
      after = ["podman.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [pkgs.podman];
      script = ''
        # Create network if it doesn't exist
        if ! podman network exists homelab; then
          podman network create homelab
          echo "Created homelab network"
        else
          echo "homelab network already exists"
        fi
      '';
    };
  };
}
