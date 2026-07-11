# Remote Pi Relay - Self-hosted WebSocket relay for the Remote Pi extension
# https://github.com/jacobaraujo7/remote_pi/blob/main/relay/README.md
{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.services.remote-pi-relay;
  homelab = config.homelab;
in {
  options.homelab.services.remote-pi-relay = {
    enable = lib.mkEnableOption "Remote Pi self-hosted WebSocket relay";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3737;
      description = "Port the relay container listens on (host-side)";
    };

    image = lib.mkOption {
      type = lib.types.str;
      default = "jacobmoura7/remote-pi-relay:latest";
      description = "OCI image for the relay";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/remote-pi-relay";
      description = "Persistent data directory (stores mesh.db)";
    };

    logLevel = lib.mkOption {
      type = lib.types.str;
      default = "info";
      description = "RUST_LOG level (error, warn, info, debug, trace)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Persistent data dir owned by root (podman rootful)
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];

    virtualisation.oci-containers.containers.remote-pi-relay = {
      image = cfg.image;
      ports = ["127.0.0.1:${toString (cfg.port + 1)}:${toString cfg.port}"];
      volumes = ["${cfg.dataDir}:/data"];
      environment = {
        REMOTEPI_RELAY_PORT = toString cfg.port;
        RUST_LOG = cfg.logLevel;
      };
      extraOptions = ["--network=homelab"];
    };

    # Caddy: LAN access via ws://larkbox:3737 (or whatever hostname)
    services.caddy.virtualHosts = lib.mkIf homelab.services.enableReverseProxy {
      "http://${homelab.hostname}:${toString cfg.port}" = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString (cfg.port + 1)}
        '';
      };
    };

    # Open firewall so phones/devices on the local network can reach the relay
    networking.firewall.allowedTCPPorts = [cfg.port];
  };
}
