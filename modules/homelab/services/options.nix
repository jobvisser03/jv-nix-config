# Homelab services infrastructure - Caddy reverse proxy and Podman setup
{lib, ...}: {
  flake.modules.homelab.services-base = {
    config,
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

    config = lib.mkIf (cfg.enable && cfg.services.enable) {
      # Open firewall for HTTP (local network + Tailscale, no HTTPS needed)
      networking.firewall.allowedTCPPorts = lib.mkIf cfg.services.enableReverseProxy [80];

      # Caddy reverse proxy (HTTP only, encrypted via Tailscale tunnel when accessing remotely)
      services.caddy = lib.mkIf cfg.services.enableReverseProxy {
        enable = true;
        globalConfig = ''
          # HTTP only - no automatic HTTPS
          # Encryption provided by Tailscale tunnel for remote access
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
  };
}
