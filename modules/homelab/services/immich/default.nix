# Immich - Self-hosted photo and video management
{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.services.immich;
  homelab = config.homelab;

  # Convert mount paths to systemd unit names for rclone service dependencies
  # e.g., "pcloud-photos" -> "rclone-pcloud-photos.service"
  externalLibraryServices = map (dir:
    let
      # Find which rclone mount corresponds to this directory
      matchingMounts = lib.filterAttrs (_: mount: mount.mountpoint == dir) config.homelab.services.rclone.mounts;
      mountNames = lib.attrNames matchingMounts;
    in
      if mountNames != [] then "rclone-${lib.head mountNames}.service" else null
  ) cfg.externalLibraryDirs;

  # Filter out nulls (directories that aren't rclone mounts)
  rcloneServiceDeps = lib.filter (x: x != null) externalLibraryServices;
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
      default = "/var/lib/immich";
      description = "Path to store Immich internal data (uploads, thumbnails, transcodes, etc.)";
    };

    externalLibraryDirs = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      example = ["/mnt/photos" "/mnt/external-drive/pictures"];
      description = ''
        Paths to external photo libraries. These directories will be bind-mounted
        read-only into Immich's sandboxed environment, allowing them to be used
        as external libraries in the Immich UI.

        After deployment, configure external libraries in Immich:
        Administration → External Libraries → Add library with these paths.
      '';
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

    # Override systemd services to allow access to external library directories
    # Immich runs with PrivateMounts=true, so we need to bind-mount external paths
    systemd.services.immich-server = lib.mkIf (cfg.externalLibraryDirs != []) {
      # Wait for rclone mounts to be ready (if external libs are rclone mounts)
      after = rcloneServiceDeps;
      wants = rcloneServiceDeps;
      serviceConfig = {
        # Bind-mount external library directories as read-only into the service's namespace
        BindReadOnlyPaths = cfg.externalLibraryDirs;
      };
    };

    systemd.services.immich-machine-learning = lib.mkIf (cfg.externalLibraryDirs != []) {
      after = rcloneServiceDeps;
      wants = rcloneServiceDeps;
      serviceConfig = {
        BindReadOnlyPaths = cfg.externalLibraryDirs;
      };
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
