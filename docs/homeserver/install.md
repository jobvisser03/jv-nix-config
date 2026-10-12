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
2. **FritzBox**:
   - Reserve a fixed IP for `homeserver`.
   - Confirm larkbox keeps `192.168.178.190`, the Tang URL baked into
     `networkUnlock.tangServers`.
3. Boot the NixOS installer through JetKVM virtual media and clone this repo.
4. Fill in the disk IDs:

   ```sh
   ls -l /dev/disk/by-id/ | grep -v part
   ```

   Replace the `REPLACE-ME` paths in `_disko-nvme.nix` (NVMe) and `_disko-tank.nix`
   (`ata-…` for each HDD). Evaluation fails until all of them are replaced.
5. Check the NIC driver the initrd needs and update
   `networkUnlock.initrdKernelModules` if it is not `r8169`:

   ```sh
   readlink /sys/class/net/*/device/driver
   ```

## Installation

```sh
# ZFS encryption key, used by disko at pool creation.
openssl rand -hex 32 | tr -d '\n' > /tmp/tank.key
chmod 0400 /tmp/tank.key
# Store a copy of this key in KeePass NOW. Losing it loses the pool.

# Destructive: NVMe root (prompts for the LUKS passphrase), then the HDD pool.
# Store the LUKS passphrase in KeePass too: it is the fallback for every boot
# where Tang or the TPM does not answer.
sudo nix run github:nix-community/disko -- --mode disko modules/hosts/homeserver/_disko-nvme.nix
sudo nix run github:nix-community/disko -- --mode disko modules/hosts/homeserver/_disko-tank.nix

# Put the key where the installed system loads it from (now on LUKS).
sudo install -D -m 0400 /tmp/tank.key /mnt/etc/zfs/keys/tank.key
zfs get keylocation tank   # expect file:///etc/zfs/keys/tank.key

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

# Export so the installed system (different hostid) can import cleanly.
sudo zpool export tank
reboot
```

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

1. Samba password: `sudo smbpasswd -a job`.
2. Verify:

   ```sh
   zpool status tank
   zfs get encryption,keystatus tank
   ras-mc-ctl --status            # ECC/EDAC driver loaded
   systemctl list-timers 'pcloud-*' 'sanoid*'
   vainfo                         # radeonsi VAAPI profiles
   ```

3. Trigger the first photo pull manually (it is large):
   `sudo systemctl start pcloud-photos-pull`.
4. If the framework should also use homeserver's Tang, add its reserved IP to
   `tangServers` in `modules/hosts/framework-13-pro/default.nix`. Then run
   `sudo network-unlock bind --replace` on the framework.

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
