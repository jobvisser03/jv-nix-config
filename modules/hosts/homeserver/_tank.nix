# Runtime for the `tank` pool: scrubs, snapshots, dataset ownership.
# Imported only when `tank` is enabled in default.nix. Layout is in _disko-tank.nix.
{
  config,
  username,
  ...
}: {
  services.zfs.autoScrub = {
    enable = true;
    interval = "monthly";
  };

  # Snapshots per dataset. tank/media is replaceable and not snapshotted.
  # tank/photos snapshots guard the pCloud mirror against upstream deletions.
  services.sanoid = {
    enable = true;
    templates = {
      default = {
        hourly = 24;
        daily = 30;
        monthly = 12;
        autosnap = true;
        autoprune = true;
      };
      mirror = {
        hourly = 0;
        daily = 14;
        monthly = 3;
        autosnap = true;
        autoprune = true;
      };
    };
    datasets = {
      "tank/documents".useTemplate = ["default"];
      "tank/immich".useTemplate = ["default"];
      "tank/backups".useTemplate = ["mirror"];
      "tank/photos".useTemplate = ["mirror"];
    };
  };

  # Set top-level dataset ownership once the pool is mounted. Not recursive:
  # contents keep whatever ownership the writing service/user gives them.
  # tank/immich is owned by the Immich module (services.immich.mediaLocation).
  systemd.services.tank-permissions = {
    description = "Set ownership of tank dataset roots";
    wantedBy = ["multi-user.target"];
    unitConfig.RequiresMountsFor = [
      "/tank/photos"
      "/tank/media"
      "/tank/documents"
      "/tank/backups"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      chown root:root /tank/photos && chmod 0755 /tank/photos
      chown ${username}:${config.homelab.group} /tank/media && chmod 2775 /tank/media
      chown ${username}:users /tank/documents && chmod 0750 /tank/documents
      chown ${username}:users /tank/backups && chmod 0750 /tank/backups
    '';
  };
}
