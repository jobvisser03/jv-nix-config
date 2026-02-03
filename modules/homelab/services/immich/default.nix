# Immich - Self-hosted photo and video management
{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.services.immich;
  homelab = config.homelab;
in {
  options.homelab.services.immich = {
    enable = lib.mkEnableOption "Immich - Self-hosted photo and video management";

    port = lib.mkOption {
      type = lib.types.port;
      default = 2283;
      description = "Port for Immich web interface";
    };

    mediaDir = lib.mkOption {
      type = lib.types.path;
      default = homelab.mounts.photos;
      description = "Path to store photos and videos";
    };

    # Homepage dashboard integration
    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Immich";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Photo & video management";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "immich.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Media";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Create media directory with proper permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir} 0775 immich ${homelab.group} - -"
    ];

    # Add immich user to video/render groups for Intel Quick Sync hardware acceleration
    users.users.immich.extraGroups = ["video" "render"];

    # Immich service configuration
    services.immich = {
      enable = true;
      port = cfg.port;
      mediaLocation = cfg.mediaDir;
      group = homelab.group;
      # Bind to all interfaces when reverse proxy is disabled
      host =
        if homelab.services.enableReverseProxy
        then "127.0.0.1"
        else "0.0.0.0";
      # Hardware acceleration is automatically enabled when available
    };

    # Caddy reverse proxy
    services.caddy.virtualHosts = lib.mkIf homelab.services.enableReverseProxy {
      "http://${homelab.hostname}:${toString cfg.port}" = {
        extraConfig = ''
          reverse_proxy http://${config.services.immich.host}:${toString config.services.immich.port}
        '';
      };
      # Also serve at /photos path on main hostname
      "http://${homelab.hostname}/photos/*" = {
        extraConfig = ''
          uri strip_prefix /photos
          reverse_proxy http://${config.services.immich.host}:${toString config.services.immich.port}
        '';
      };
    };

    # Open firewall for direct access when reverse proxy is disabled
    networking.firewall.allowedTCPPorts = lib.mkIf (!homelab.services.enableReverseProxy) [cfg.port];
  };
}
