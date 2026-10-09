# Homeserver

Headless NixOS NAS and media server. Console access via JetKVM.

> **Install warning:** disko formatting is destructive. `_disko-tank.nix` wipes all five HDDs; `_disko-nvme.nix` wipes the NVMe. Verify every `/dev/disk/by-id` path before running either.

## Design

- Host: `homeserver`, profiles `common-nixos` + `common-shell` + `common-dev` (no desktop)
- Hardware: Ryzen 5 7600, ASRock B650M RS Pro, 32 GB ECC, 1 TB NVMe, 5× 10 TB SATA HDD
- Boot: UEFI, systemd-boot (no Secure Boot / LUKS / TPM)
- Root: NVMe → 1 GiB ESP + BTRFS (`/root`, `/home`, `/nix`, `/var-lib` → `/var/lib`), zram swap
- Data: ZFS pool `tank`, RAIDZ2 over 5 HDDs (~30 TB usable), native encryption with a keyfile at `/etc/zfs/keys/tank.key` on the NVMe (unattended boot; protects removed disks)
- Datasets: `tank/photos` (pCloud mirror), `tank/immich`, `tank/media` (Jellyfin), `tank/documents`, `tank/backups`. All mounted `nofail` so a pool problem never blocks SSH.
- Snapshots (sanoid): documents/immich hourly 24, daily 30, monthly 12; photos/backups daily 14, monthly 3; media none
- Health: monthly scrub, smartd, rasdaemon (ECC). Notifications not yet wired up.
- Shares: Samba (SMB3, macOS fruit) and NFSv4, limited to LAN subnet + Tailscale
- pCloud: nightly pull of camera photos into `tank/photos` (01:00); nightly push of documents, backups and Immich originals to `pcloud:HOMESERVER-BACKUP` (04:00)
- Services: `homelab` imported; Immich (`/tank/immich`) and Jellyfin (`/tank/media`) preconfigured but disabled until migration from larkbox. Transcoding via VAAPI on the Radeon iGPU.

| File | Purpose |
| --- | --- |
| `modules/hosts/homeserver/default.nix` | Host identity, boot, network, homelab wiring |
| `_disko-nvme.nix` | Root disk layout |
| `_disko-tank.nix` | ZFS pool and datasets |
| `_storage.nix` | ZFS runtime, sanoid, smartd, rasdaemon, dataset ownership |
| `_shares.nix` | Samba + NFS |
| `_pcloud.nix` | rclone pull/push timers |
| `_secrets.nix` | sops secrets |

## Before installation

1. BIOS: enable ECC (if exposed), keep the iGPU enabled, set "Restore on AC power loss" to Power On, boot UEFI only.
2. Boot the NixOS installer via JetKVM virtual media. Clone this repo.
3. Fill in disk ids:

   ```sh
   ls -l /dev/disk/by-id/ | grep -v part
   ```

   Replace `REPLACE-ME` paths in `_disko-nvme.nix` (NVMe) and `_disko-tank.nix` (`ata-…` for each HDD). Evaluation fails until all are replaced.
4. Check `lanSubnet` in `_shares.nix` matches your router.

## Installation

```sh
# ZFS encryption key, used by disko at pool creation.
openssl rand -hex 32 | tr -d '\n' > /tmp/tank.key
chmod 0400 /tmp/tank.key
# Store a copy of this key in KeePass NOW. Losing it loses the pool.

# Destructive: NVMe root, then HDD pool.
sudo nix run github:nix-community/disko -- --mode disko modules/hosts/homeserver/_disko-nvme.nix
sudo nix run github:nix-community/disko -- --mode disko modules/hosts/homeserver/_disko-tank.nix

# Put the key where the installed system loads it from.
sudo install -D -m 0400 /tmp/tank.key /mnt/etc/zfs/keys/tank.key
zfs get keylocation tank   # expect file:///etc/zfs/keys/tank.key

# Machine-specific hardware data.
sudo nixos-generate-config --no-filesystems --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix modules/hosts/homeserver/_hardware-configuration.nix

sudo nixos-install --flake .#homeserver --root /mnt

# Export so the installed system (different hostid) can import cleanly.
sudo zpool export tank
reboot
```

## After first boot

1. Add the host to sops:

   ```sh
   ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
   ```

   Uncomment `&homeserver` in `.sops.yaml` with that value, uncomment `*homeserver` in the `shared.yaml` rule, then on a machine that can decrypt: `sops updatekeys secrets/shared.yaml`. Rebuild.
2. Samba password: `sudo smbpasswd -a job`.
3. Verify:

   ```sh
   zpool status tank
   zfs get encryption,keystatus tank
   ras-mc-ctl --status            # ECC/EDAC driver loaded
   systemctl list-timers 'pcloud-*' 'sanoid*'
   vainfo                         # radeonsi VAAPI profiles
   ```

4. Trigger the first photo pull manually (large): `sudo systemctl start pcloud-photos-pull`.

## Reinstalling the root disk

Only run `_disko-nvme.nix`. The pool imports automatically on boot as long as `networking.hostId` is unchanged and `/etc/zfs/keys/tank.key` is restored from KeePass before switching to the new system.

## Migrating media from larkbox

1. homeserver: set `homelab.services.enable = true`, `enablePublicHttps = true`, enable `immich`, `jellyfin`, `cloudflare-ddns` and `homepage`; add Immich to `nixpkgs.config.permittedInsecurePackages` as on larkbox; add host secrets (`cloudflare_ddns_token`).
2. larkbox: disable `immich`, `cloudflare-ddns`, public HTTPS and the pCloud photo mounts.
3. Port-forward 80/443 on the router to homeserver.
4. In Immich, add the external libraries `/tank/photos/PHOTOS-PCLOUD` and `/tank/photos/SMARTPHONE-PHOTOS-PCLOUD`; in Jellyfin select VAAPI (`/dev/dri/renderD128`).

## Deferred

- Alerting for ZED / smartd / rasdaemon (ntfy, email or Signal)
- Add `homeserver` to the CI matrix in `.github/workflows/cachix.yml` once disk ids are filled in
