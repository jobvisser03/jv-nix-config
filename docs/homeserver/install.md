# Homeserver install

> **Install warning:** disko formatting is destructive. `_disko-tank.nix` wipes
> all five HDDs; `_disko-nvme.nix` wipes the NVMe. Verify every
> `/dev/disk/by-id` path before running either.

## Before installation

1. **BIOS**:
   - Boot UEFI only, with Secure Boot **disabled**.
   - Enable AMD fTPM.
   - Enable ECC (if exposed).
   - Keep the iGPU enabled.
   - Set "Restore on AC power loss" to Power On.
2. **FritzBox**: the reservations are already in place: homeserver
   `192.168.178.43`, larkbox `192.168.178.190` (the Tang URL baked into
   `networkUnlock.tangServers`), JetKVM `192.168.178.158`. Check that the
   homeserver's MAC matches its reservation after first boot.
3. Boot the NixOS installer through JetKVM virtual media and clone this repo.
4. Fill in the NVMe disk ID in `_disko-nvme.nix`:

   ```sh
   ls -l /dev/disk/by-id/ | grep -v part
   ```

   Evaluation fails while a `REPLACE-ME` path remains in an imported disko file.
   With `tank = false` in `default.nix` only the NVMe is imported. The HDD IDs
   are filled in later; see [Creating `tank` later](#creating-tank-later).
5. Check the NIC driver the initrd needs and update
   `networkUnlock.initrdKernelModules` if it is not `r8169`:

   ```sh
   readlink /sys/class/net/*/device/driver
   ```

## Installation

This installs the NVMe-only system (`tank = false`). The HDDs stay untouched.

```sh
# Destructive to the NVMe: prompts for the LUKS passphrase. Store it in
# KeePass: it is the fallback for every boot where Tang or the TPM fails.
sudo nix run github:nix-community/disko -- --mode disko modules/hosts/homeserver/_disko-nvme.nix

# Host key for the initrd unlock sshd (port 2222). It must exist before
# nixos-install: the bootloader step embeds it into the initrd.
sudo install -d -m 0700 /mnt/etc/secrets/initrd
sudo ssh-keygen -t ed25519 -N '' -C homeserver-initrd \
  -f /mnt/etc/secrets/initrd/ssh_host_ed25519_key

# Machine-specific hardware data.
sudo nixos-generate-config --no-filesystems --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix modules/hosts/homeserver/_hardware-configuration.nix

sudo nixos-install --flake .#homeserver --root /mnt
# If Lanzaboote refuses because no keys exist yet:
#   sudo nixos-enter --root /mnt -c 'sbctl create-keys'   and rerun nixos-install.
reboot
```

Commit the NVMe ID and the generated `_hardware-configuration.nix`.
The first boot asks for the LUKS passphrase. Type it through JetKVM, or run
`ssh -p 2222 root@homeserver` from the LAN.

## After first boot

### sops

```sh
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

1. Uncomment `&homeserver` in `.sops.yaml` with that value.
2. Uncomment `*homeserver` in the `shared.yaml` rule.
3. On a machine that can decrypt, run `sops updatekeys secrets/shared.yaml`.
4. Rebuild.

### Secure Boot

Same flow as the framework (see [../framework-13-pro.md](../framework-13-pro.md#secure-boot)):

```sh
sudo sbctl status                     # keys exist under /var/lib/sbctl
sudo nixos-rebuild switch --flake .#homeserver   # signs boot artifacts
```

1. In the ASRock BIOS (via JetKVM), clear the Secure Boot keys to enter setup
   mode.
2. Enroll the keys:

   ```sh
   sudo sbctl enroll-keys --microsoft
   ```

3. Set Secure Boot to enabled/enforced in the BIOS and reboot.
4. Run `bootctl status` and expect `Secure Boot: enabled (user)`.
5. Back up `/var/lib/sbctl` to KeePass or another safe store.

### Network unlock

Bind only after Secure Boot is enforced, so PCR 7 is already final.

```sh
ssh larkbox tang-show-keys 7654       # thumbprint to compare against
sudo network-unlock bind              # confirm thumbprint, enter LUKS passphrase
sudo network-unlock status
sudo reboot                           # should come up with no prompt
```

Test the fallback once. Stop Tang on larkbox (`sudo systemctl stop tangd.socket`),
reboot homeserver, and unlock with `ssh -p 2222 root@homeserver`. Start Tang
again afterwards.

### Remaining steps

1. Verify:

   ```sh
   ras-mc-ctl --status            # ECC/EDAC driver loaded
   vainfo                         # radeonsi VAAPI profiles
   sudo network-unlock status
   ```

2. Make homeserver the framework's second Tang server:
   1. On the framework, run `curl -fsS http://192.168.178.43:7654/adv` to check
      it answers.
   2. Uncomment the two-server `tangServers` line in
      `modules/hosts/framework-13-pro/default.nix` and rebuild.
   3. Run `sudo network-unlock bind --replace`.
3. Once the fifth HDD is connected: [Creating `tank` later](#creating-tank-later).

## Creating `tank` later

Do this on the running system once all five HDDs are connected. RAIDZ2 width
is fixed at creation, so wait for the fifth disk rather than creating a
four-disk pool. OpenZFS can widen a RAIDZ vdev afterwards, but data written
before that keeps the 2:2 data/parity ratio, so you lose capacity.

1. Confirm all five drives are visible, then fill the `ata-…` IDs into
   `_disko-tank.nix`:

   ```sh
   ls -l /dev/disk/by-id/ | grep -E '^.*ata-' | grep -v part
   sudo smartctl -H /dev/disk/by-id/ata-…        # each drive: PASSED
   ```

2. Create the key and the pool:

   ```sh
   # ZFS encryption key. Store a copy in KeePass NOW: losing it loses the pool.
   openssl rand -hex 32 | tr -d '\n' | sudo tee /tmp/tank.key >/dev/null
   sudo chmod 0400 /tmp/tank.key
   sudo install -D -m 0400 /tmp/tank.key /etc/zfs/keys/tank.key   # LUKS root

   # Destructive to the five HDDs only. Triple-check the IDs first.
   sudo nix run github:nix-community/disko -- --mode disko modules/hosts/homeserver/_disko-tank.nix
   zfs get keylocation tank   # expect file:///etc/zfs/keys/tank.key
   sudo shred -u /tmp/tank.key
   sudo umount -R /mnt/tank 2>/dev/null || true   # disko's temporary mounts
   ```

3. Set `tank = true` in `modules/hosts/homeserver/default.nix`. This imports
   `_disko-tank.nix`, `_tank.nix`, `_shares.nix` and `_pcloud.nix`. Then:

   ```sh
   sudo nixos-rebuild switch --flake .#homeserver
   sudo reboot        # proves the pool imports and its key loads at boot
   ```

4. Finish:
   1. Samba password: `sudo smbpasswd -a job`.
   2. Verify:

      ```sh
      zpool status tank
      zfs get encryption,keystatus tank
      systemctl list-timers 'pcloud-*' 'sanoid*' 'zfs-scrub*'
      ls -ld /tank/*                 # ownership set by tank-permissions
      ```

   3. Trigger the first photo pull manually (it is large):
      `sudo systemctl start pcloud-photos-pull`.

## Migrating media from larkbox

1. homeserver:
   - Set `homelab.services.enable = true` and `enablePublicHttps = true`.
   - Enable `immich`, `jellyfin`, `cloudflare-ddns` and `homepage`.
   - Add Immich to `nixpkgs.config.permittedInsecurePackages`, as on larkbox.
   - Add the host secrets (`cloudflare_ddns_token`).
2. larkbox: disable `immich`, `cloudflare-ddns`, public HTTPS and the pCloud
   photo mounts. **Keep `nixos/tang-server`**: homeserver unlocks through it.
3. Port-forward 80/443 on the router to homeserver.
4. In Immich, add the external libraries `/tank/photos/PHOTOS-PCLOUD` and
   `/tank/photos/SMARTPHONE-PHOTOS-PCLOUD`. In Jellyfin, select VAAPI
   (`/dev/dri/renderD128`).
