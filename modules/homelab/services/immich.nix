# Immich - Self-hosted photo and video management
{lib, ...}: {
  flake.modules.homelab.immich = {
    config,
    pkgs,
    ...
  }: let
    cfg = config.homelab.services.immich;
    homelab = config.homelab;

    # Convert mount paths to systemd unit names for rclone service dependencies
    externalLibraryServices =
      map (
        dir: let
          matchingMounts = lib.filterAttrs (_: mount: mount.mountpoint == dir) config.homelab.services.rclone.mounts;
          mountNames = lib.attrNames matchingMounts;
        in
          if mountNames != []
          then "rclone-${lib.head mountNames}.service"
          else null
      )
      cfg.externalLibraryDirs;

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
        description = "Path to store Immich internal data";
      };

      externalLibraryDirs = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [];
        description = "Paths to external photo libraries";
      };

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
      users.users.immich.extraGroups = ["video" "render"];

      services.immich = {
        enable = true;
        port =
          if homelab.services.enableReverseProxy
          then cfg.port + 10000
          else cfg.port;
        mediaLocation = cfg.mediaDir;
        group = homelab.group;
        host =
          if homelab.services.enableReverseProxy
          then "127.0.0.1"
          else "0.0.0.0";
      };

      systemd.services.immich-server = lib.mkIf (cfg.externalLibraryDirs != []) {
        after = rcloneServiceDeps;
        wants = rcloneServiceDeps;
        serviceConfig = {
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

      services.caddy.virtualHosts = lib.mkIf homelab.services.enableReverseProxy {
        "http://${homelab.hostname}:${toString cfg.port}" = {
          extraConfig = ''
            reverse_proxy http://127.0.0.1:${toString (cfg.port + 10000)}
          '';
        };
        "http://${homelab.hostname}/photos/*" = {
          extraConfig = ''
            uri strip_prefix /photos
            reverse_proxy http://127.0.0.1:${toString (cfg.port + 10000)}
          '';
        };
      };

      networking.firewall.allowedTCPPorts = [cfg.port];
    };
  };
}
