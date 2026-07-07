# Rclone - Cloud storage mounts via rclone
# Supports mounting pCloud and other cloud providers as local filesystems
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.rclone;
in {
  options.services.rclone = {
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
            example = "/home/job/pcloud";
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
          requiredMounts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            example = ["/mnt/usb-drive"];
            description = "Filesystem mounts that must be available before this rclone mount starts";
          };
        };
      });
      default = {};
      description = "Rclone mount definitions";
    };

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
    environment.systemPackages = [pkgs.rclone pkgs.fuse];

    programs.fuse.userAllowOther = true;

    systemd.tmpfiles.rules =
      lib.mapAttrsToList
      (name: mount: "d ${mount.mountpoint} 0755 root root - -")
      cfg.mounts;

    systemd.paths.rclone-config-watcher = {
      description = "Watch for rclone config file (sops secret)";
      wantedBy = ["multi-user.target"];
      pathConfig = {
        PathExists = cfg.configFile;
        Unit = "rclone-mounts.target";
      };
    };

    systemd.targets.rclone-mounts = {
      description = "All rclone mount services";
      after = ["network.target" "sops-nix.service"];
      wants = lib.mapAttrsToList (name: _: "rclone-${name}.service") cfg.mounts;
      wantedBy = ["multi-user.target"];
    };

    systemd.services = lib.mapAttrs' (name: mount: let
      pathToUnit = path: let
        cleaned = lib.removePrefix "/" path;
        parts = lib.splitString "/" cleaned;
        escapedParts = map (part: builtins.replaceStrings ["-"] ["\\x2d"] part) parts;
        escaped = lib.concatStringsSep "-" escapedParts;
      in "${escaped}.mount";
      requiredMountUnits = map pathToUnit mount.requiredMounts;
    in
      lib.nameValuePair "rclone-${name}" {
        description = "rclone mount: ${name} (${mount.remote} -> ${mount.mountpoint})";
        after = ["network.target" "sops-nix.service"] ++ requiredMountUnits;
        wants = ["network.target"];
        requires = requiredMountUnits;
        wantedBy = [];
        partOf = ["rclone-mounts.target"];

        unitConfig = {
          ConditionPathExists = cfg.configFile;
        };

        serviceConfig = {
          Type = "notify";
          ExecStartPre = [
            "${pkgs.coreutils}/bin/mkdir -p ${mount.mountpoint}"
            "-${pkgs.fuse}/bin/fusermount -uz ${mount.mountpoint}"
          ];
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
            # Resilience hardening for network (cloud) FUSE mounts.
            #
            # Problem this solves: a heavy metadata scan over the mount (e.g.
            # Immich's nightly library scan stat()-ing tens of thousands of
            # files) will, whenever the cloud backend stalls, park kernel
            # threads in uninterruptible D-state inside vfs_statx waiting for
            # rclone to answer. rclone's default --timeout is 5 minutes, so
            # each stuck call blocks for up to 5 min - long enough to trip
            # hung_task and pile up enough blocked threads to hard-hang the
            # box (the root cause of the recurring 02:00 freezes on larkbox).
            #
            #   --timeout / --contimeout : cap how long a stalled backend
            #       call blocks before rclone returns EIO to the kernel,
            #       so a FUSE stat() fails fast instead of hanging in D-state.
            #   --dir-cache-time         : keep directory listings cached so a
            #       full-tree scan is served from memory, not the network.
            #   --poll-interval          : still detect backend changes (pcloud
            #       supports polling) so new uploads appear despite the cache.
            #   --attr-timeout           : let the kernel cache file attrs a
            #       little longer, cutting per-file stat round-trips.
            hardeningArgs = lib.concatStringsSep " " [
              "--timeout 1m"
              "--contimeout 15s"
              "--low-level-retries 3"
              "--dir-cache-time 24h"
              "--poll-interval 1m"
              "--attr-timeout 5s"
            ];
          in ''
            ${pkgs.rclone}/bin/rclone mount \
              --config=${cfg.configFile} \
              --vfs-cache-mode ${mount.cacheMode} \
              --allow-other \
              --allow-non-empty \
              ${hardeningArgs} \
              ${uidArg} \
              ${gidArg} \
              ${readOnlyArg} \
              ${extraArgsStr} \
              ${mount.remote} ${mount.mountpoint}
          '';
          ExecStop = "${pkgs.fuse}/bin/fusermount -uz ${mount.mountpoint}";
          Restart = "on-failure";
          RestartSec = "10s";
          TimeoutStartSec = "60s";
        };
      })
    cfg.mounts;
  };
}
