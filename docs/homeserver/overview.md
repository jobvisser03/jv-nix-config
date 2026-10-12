# Homeserver overview

Headless NixOS NAS and media server. Console access is through JetKVM.

| Doc | Use it for |
| --- | --- |
| [install.md](install.md) | First install, Secure Boot, network unlock, sops |
| [operations.md](operations.md) | Deploys, unlock, routine checks |
| [recovery.md](recovery.md) | When SSH or boot fails; reinstalling the root disk |
| [roadmap.md](roadmap.md) | Deferred work and ideas taken from Riezebos/nix `foundry` |
| [../network-unlock.md](../network-unlock.md) | Clevis + Tang + TPM2, shared with the framework |

## Hardware

| Component | Detail |
| --- | --- |
| CPU | AMD Ryzen 5 7600 (RDNA2 iGPU for VAAPI) |
| Board | ASRock B650M RS Pro, fTPM, Realtek 2.5GbE (`r8169`) |
| RAM | 32 GB ECC |
| Root | 1 TB NVMe |
| Data | 5× 10 TB SATA HDD |
| Console | JetKVM |

## Design

- Host `homeserver`, profiles `common-nixos` + `common-shell` + `common-dev` (no desktop).
- Boot: UEFI, Lanzaboote Secure Boot, systemd initrd.
- Root: NVMe → 1 GiB ESP → **LUKS2** → BTRFS (`/root`, `/home`, `/nix`,
  `/var-lib` → `/var/lib`), zram swap.
- Unlock: Clevis Tang (larkbox) + TPM2 PCR 7. Fallbacks are the initrd SSH
  service on port 2222 and the JetKVM console.
- Data: ZFS pool `tank`, RAIDZ2 over 5 HDDs (~30 TB usable).
  - Native encryption with a keyfile at `/etc/zfs/keys/tank.key`. That file
    sits on the LUKS root, so it is encrypted at rest.
  - Boot stays unattended.
- Datasets: `tank/photos` (pCloud mirror), `tank/immich`, `tank/media`
  (Jellyfin), `tank/documents`, `tank/backups`. All are mounted `nofail`, so a
  pool problem never blocks SSH.
- Snapshots (sanoid):
  - documents/immich: hourly 24, daily 30, monthly 12
  - photos/backups: daily 14, monthly 3
  - media: none
- Health: monthly scrub, smartd, rasdaemon (ECC). Notifications are not wired up
  yet.
- Shares: Samba (SMB3, macOS fruit) and NFSv4, limited to `192.168.178.0/24`
  and Tailscale.
- pCloud (nightly):
  - 01:00: pull camera photos into `tank/photos`
  - 04:00: push documents, backups and Immich originals to
    `pcloud:HOMESERVER-BACKUP`
- Services: `homelab` is imported. Immich (`/tank/immich`) and Jellyfin
  (`/tank/media`) are configured but disabled until the migration from larkbox.
  Transcoding uses VAAPI on the iGPU.
- Tang server for the framework, once homeserver's IP is reserved.

## Security model

| Port | Exposure | Purpose |
| --- | --- | --- |
| 22 | LAN + Tailscale | Main sshd, key-only, no root, no passwords |
| 2222 | LAN, initrd only | LUKS passphrase prompt (`ForceCommand systemd-tty-ask-password-agent`) |
| 445 / 2049 | LAN + Tailscale (host allow lists) | Samba / NFSv4 |
| 7654 | LAN only (`IPAddressAllow`) | Tang |
| 41641/udp | any | Tailscale |

- Nothing is port-forwarded until the larkbox migration day (80/443 for Caddy).
- `tailscale0` is a trusted interface.
- Passwordless sudo for `job` makes password SSH equivalent to root, so
  password auth is off.
- The initrd SSH host key differs from the main one. They use different ports, so
  `known_hosts` keeps them apart (`[homeserver]:2222`).

## Files

| File | Purpose |
| --- | --- |
| `modules/hosts/homeserver/default.nix` | Host identity, boot, SSH, network unlock, homelab wiring |
| `_disko-nvme.nix` | Root disk layout (ESP + LUKS + BTRFS) |
| `_disko-tank.nix` | ZFS pool and datasets |
| `_storage.nix` | ZFS runtime, sanoid, smartd, rasdaemon, dataset ownership |
| `_shares.nix` | Samba + NFS |
| `_pcloud.nix` | rclone pull/push timers |
| `_secrets.nix` | sops secrets |
| `modules/nixos/network-unlock/` | Clevis/Tang module and `network-unlock` helper |
