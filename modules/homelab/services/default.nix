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
