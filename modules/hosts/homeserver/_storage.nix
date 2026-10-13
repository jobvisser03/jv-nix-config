# Storage basics that do not need the data pool: ZFS support, disk health,
# ECC logging. Pool runtime (scrub, snapshots, ownership) lives in _tank.nix.
{...}: {
  boot.supportedFilesystems = ["zfs"];
  boot.zfs.forceImportRoot = false;

  # Required by ZFS; must stay stable for the lifetime of the pool.
  networking.hostId = "b2b49adc";

  # Leave room for Immich ML, Postgres and Jellyfin on 32 GB: cap ARC at 16 GiB.
  boot.kernelParams = ["zfs.zfs_arc_max=17179869184"];

  # Disk health. Notifications are deferred; failures go to the journal and wall.
  services.smartd = {
    enable = true;
    autodetect = true;
  };

  # ECC memory: log corrected/uncorrected errors (amd64_edac) to
  # /var/lib/rasdaemon. Check with `ras-mc-ctl --status` / `--summary`.
  hardware.rasdaemon.enable = true;
}
