# Boot/root NVMe layout for homeserver: GPT -> 1 GiB ESP -> BTRFS.
#
# Kept separate from _disko-tank.nix so the root disk can be reinstalled
# without touching the data pool:
#   sudo nix run github:nix-community/disko -- --mode disko modules/hosts/homeserver/_disko-nvme.nix
#
# Plain attrset (no function args) so the disko CLI can consume this file
# directly as well as through the NixOS module system.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-HOMESERVER-REPLACE-ME";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };

        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = ["-f"];
            subvolumes = {
              "/root" = {
                mountpoint = "/";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = ["compress=zstd" "noatime"];
              };
              # Service state (Immich Postgres, Jellyfin metadata/cache) on
              # fast NVMe, separately snapshottable from the root subvolume.
              "/var-lib" = {
                mountpoint = "/var/lib";
                mountOptions = ["compress=zstd" "noatime"];
              };
            };
          };
        };
      };
    };
  };
}
