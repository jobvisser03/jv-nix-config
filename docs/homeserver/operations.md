# Homeserver operations

Routine commands. Run them from the framework unless noted.

## Unlock after reboot

Normally nothing is needed: Tang on larkbox plus the TPM unlock the root. If the
box sits at the passphrase prompt (larkbox down, Wi-Fi/LAN issue, PCR 7
changed), unlock it remotely:

```sh
ssh -p 2222 root@homeserver     # lands directly on the LUKS prompt
```

The session closes when the real system takes over. JetKVM is the fallback when
the network is unavailable. If the prompt appeared because PCR 7 changed,
rebind afterwards (see [../network-unlock.md](../network-unlock.md#after-firmware-bios-or-secure-boot-changes)).

| Port | Meaning |
| --- | --- |
| 22 | main sshd |
| 2222 | initrd LUKS unlock sshd |

## Deploy

On the box:

```sh
sudo nixos-rebuild switch --flake ~/repos/jv-nix-config#homeserver
```

Remotely, building on homeserver itself:

```sh
nixos-rebuild switch --flake .#homeserver \
  --target-host job@homeserver --build-host job@homeserver --sudo
```

Neither path rolls back automatically if SSH breaks. For risky changes, use
`nixos-rebuild test` first (reboot reverts), or keep JetKVM open. See
[roadmap.md](roadmap.md#deploy-rs-with-magic-rollback).

## Health checks

```sh
ssh homeserver systemctl --failed
ssh homeserver zpool status -x                 # "all pools are healthy"
ssh homeserver sudo network-unlock status      # binding present, Tang reachable
ssh homeserver systemctl list-timers 'pcloud-*' 'sanoid*' 'zfs-scrub*'
ssh homeserver sudo smartctl -H /dev/disk/by-id/ata-…
ssh homeserver ras-mc-ctl --summary            # ECC events
ssh homeserver sudo ss -tulpn                  # listening ports vs overview.md
```

## Snapshots

```sh
ssh homeserver zfs list -t snapshot -o name,used,creation tank/documents | tail
# Restore one file from a snapshot (read-only, no rollback):
ssh homeserver ls /tank/documents/.zfs/snapshot/
```

## Key and secret inventory

Keep these outside the repo, in KeePass:

| Item | Lives on | Losing it means |
| --- | --- | --- |
| LUKS passphrase | KeePass | No unlock when Tang/TPM fail; reinstall root |
| `tank.key` | `/etc/zfs/keys/tank.key` + KeePass | **Pool lost** |
| `/var/lib/sbctl` | homeserver root + backup | Re-enroll Secure Boot keys, then rebind |
| initrd SSH host key | `/etc/secrets/initrd/` | Regenerate; accept the new key once |
| Tang keys | larkbox `/var/lib/private/tang` | Passphrase boot, then `bind --replace` |
