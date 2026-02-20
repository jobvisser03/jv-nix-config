# Homelab module - global options and service imports
{
  lib,
  config,
  ...
}: let
  cfg = config.homelab;
in {
  options.homelab = {
    enable = lib.mkEnableOption "Enable homelab services and configuration";

    # Storage paths
    mounts = {
      photos = lib.mkOption {
        type = lib.types.path;
        default = "${cfg.mounts.media}/PHOTOS-PCLOUD";
        description = "Path to photos storage for Immich";
      };
    };

    # User/group for services
    user = lib.mkOption {
      type = lib.types.str;
      default = "homelab";
      description = "User to run homelab services as";
    };
    group = lib.mkOption {
      type = lib.types.str;
      default = "homelab";
      description = "Group to run homelab services as";
    };

    # Networking
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = config.time.timeZone;
      description = "Time zone for homelab services";
    };

    # Local network hostname (used for service URLs without a domain)
    hostname = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "Hostname for accessing services (e.g., 'larkbox' -> http://larkbox:8080)";
    };
  };

  imports = [
    ./services
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
}
