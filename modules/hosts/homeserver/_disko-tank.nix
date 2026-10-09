# Data pool for homeserver: 5x 10 TB SATA HDD in RAIDZ2 (~30 TB usable).
#
# DESTRUCTIVE to all five HDDs. Run once, at first install only:
#   sudo nix run github:nix-community/disko -- --mode disko modules/hosts/homeserver/_disko-tank.nix
# Root disk reinstalls use _disko-nvme.nix only and simply re-import `tank`.
#
# Encryption: ZFS native, raw hex key stored on the NVMe at
# /etc/zfs/keys/tank.key. This protects discarded/RMA'd HDDs while keeping
# boot unattended. Losing the key means losing the pool: keep a copy in KeePass.
# The key is read from /tmp/tank.key at creation time (see docs/homeserver.md),
# then keylocation is switched to the on-disk path.
#
# Plain attrset (no function args) so the disko CLI can consume this file
# directly as well as through the NixOS module system.
let
  hdds = {
    hdd1 = "/dev/disk/by-id/ata-HOMESERVER-HDD1-REPLACE-ME";
    hdd2 = "/dev/disk/by-id/ata-HOMESERVER-HDD2-REPLACE-ME";
    hdd3 = "/dev/disk/by-id/ata-HOMESERVER-HDD3-REPLACE-ME";
    hdd4 = "/dev/disk/by-id/ata-HOMESERVER-HDD4-REPLACE-ME";
    hdd5 = "/dev/disk/by-id/ata-HOMESERVER-HDD5-REPLACE-ME";
  };

  mkHdd = device: {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions.zfs = {
        size = "100%";
        content = {
          type = "zfs";
          pool = "tank";
        };
      };
    };
  };

  # nofail: a degraded/missing pool must not block boot; SSH and JetKVM
  # stay reachable for recovery.
  mkDataset = mountpoint: options: {
    type = "zfs_fs";
    inherit mountpoint options;
    mountOptions = ["nofail"];
  };
in {
  disko.devices = {
    disk = builtins.mapAttrs (_: mkHdd) hdds;

    zpool.tank = {
      type = "zpool";
      mode = "raidz2";
      options.ashift = "12";
      rootFsOptions = {
        compression = "lz4";
        atime = "off";
        xattr = "sa";
        acltype = "posixacl";
        encryption = "aes-256-gcm";
        keyformat = "hex";
        keylocation = "file:///tmp/tank.key";
        mountpoint = "none";
        canmount = "off";
      };
      postCreateHook = "zfs set keylocation=file:///etc/zfs/keys/tank.key tank";

      datasets = {
        # Nightly one-way mirror of pCloud camera photos (Immich external library).
        photos = mkDataset "/tank/photos" {recordsize = "1M";};
        # Immich mediaLocation: uploads, library, thumbs, encoded video.
        immich = mkDataset "/tank/immich" {};
        # Jellyfin library: large sequential files.
        media = mkDataset "/tank/media" {recordsize = "1M";};
        # Personal and business documents (Samba/NFS share).
        documents = mkDataset "/tank/documents" {};
        # Machine backups from other hosts.
        backups = mkDataset "/tank/backups" {};
      };
    };
  };
}
