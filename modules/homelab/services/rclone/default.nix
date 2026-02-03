# Rclone - Cloud storage mounts via rclone
# Supports mounting pCloud and other cloud providers as local filesystems
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.rclone;
  homelab = config.homelab;
in {
  options.homelab.services.rclone = {
    enable = lib.mkEnableOption "rclone cloud storage mounts";

    configFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to rclone config file (from sops secrets)";
    };

    mounts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          remote = lib.mkOption {
            type = lib.types.str;
            example = "pcloud:PHOTOS";
            description = "Remote path in format 'remotename:path'";
          };
          mountpoint = lib.mkOption {
            type = lib.types.path;
            example = "/media/pcloud";
            description = "Local mount path";
          };
          cacheMode = lib.mkOption {
            type = lib.types.enum ["off" "minimal" "writes" "full"];
            default = "writes";
            description = "VFS cache mode - 'writes' recommended for most use cases";
          };
          readOnly = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Mount as read-only";
          };
          uid = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            description = "UID for mounted files (null = root)";
          };
          gid = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            description = "GID for mounted files (null = root)";
          };
          extraArgs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            example = ["--buffer-size=64M" "--dir-cache-time=72h"];
            description = "Additional rclone mount arguments";
          };
        };
      });
      default = {};
      description = "Rclone mount definitions";
    };

    # Homepage dashboard integration
    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Cloud Storage";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "rclone cloud mounts";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "rclone.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Storage";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Required packages
    environment.systemPackages = [pkgs.rclone pkgs.fuse];

    # Enable FUSE and allow non-root users to access mounts
    programs.fuse.userAllowOther = true;

    # Create mount directories via tmpfiles
    systemd.tmpfiles.rules =
      lib.mapAttrsToList
      (name: mount: "d ${mount.mountpoint} 0755 root root - -")
      cfg.mounts;

    # Create a systemd path unit to watch for the config file
    # This triggers the rclone services when sops-nix creates the secret
    systemd.paths.rclone-config-watcher = {
      description = "Watch for rclone config file (sops secret)";
      wantedBy = ["multi-user.target"];
      pathConfig = {
        PathExists = cfg.configFile;
        Unit = "rclone-mounts.target";
      };
    };

    # Target that groups all rclone mount services
    systemd.targets.rclone-mounts = {
      description = "All rclone mount services";
      wants = lib.mapAttrsToList (name: _: "rclone-${name}.service") cfg.mounts;
    };

    # Create a systemd service for each mount
    systemd.services =
      lib.mapAttrs' (name: mount:
        lib.nameValuePair "rclone-${name}" {
          description = "rclone mount: ${name} (${mount.remote} -> ${mount.mountpoint})";
          after = ["network-online.target"];
          wants = ["network-online.target"];
          # Don't use WantedBy - let the path watcher trigger via target
          wantedBy = [];
          partOf = ["rclone-mounts.target"];

          # Wait for sops-nix to create the config file before starting
          # This prevents the service from failing during nixos-rebuild switch
          unitConfig = {
            ConditionPathExists = cfg.configFile;
          };

          serviceConfig = {
            Type = "notify";
            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mount.mountpoint}";
            ExecStart = let
              uidArg =
                if mount.uid != null
                then "--uid ${toString mount.uid}"
                else "";
              gidArg =
                if mount.gid != null
                then "--gid ${toString mount.gid}"
                else "";
              readOnlyArg =
                if mount.readOnly
                then "--read-only"
                else "";
              extraArgsStr = lib.concatStringsSep " " mount.extraArgs;
            in ''
              ${pkgs.rclone}/bin/rclone mount \
                --config=${cfg.configFile} \
                --vfs-cache-mode ${mount.cacheMode} \
                --allow-other \
                ${uidArg} \
                ${gidArg} \
                ${readOnlyArg} \
                ${extraArgsStr} \
                ${mount.remote} ${mount.mountpoint}
            '';
            ExecStop = "${pkgs.fuse}/bin/fusermount -u ${mount.mountpoint}";
            Restart = "on-failure";
            RestartSec = "10s";
            # Give rclone time to establish connection
            TimeoutStartSec = "60s";
          };
        })
      cfg.mounts;
  };
}
