# Homeserver recovery

Use this when the routine paths in [operations.md](operations.md) are not enough.

## Recovery order

1. Main SSH: `ssh homeserver` (or over Tailscale)
2. Initrd unlock SSH while it waits for the passphrase: `ssh -p 2222 root@homeserver`
3. JetKVM console: pick an older generation in the boot menu, or type the
   passphrase
4. NixOS installer via JetKVM virtual media: mount and repair (below)
5. Reinstall the root disk only; `tank` survives

## Mount the installed system from the installer

```sh
sudo cryptsetup open /dev/disk/by-partlabel/disk-main-luks cryptroot
sudo mount -o subvol=/root /dev/mapper/cryptroot /mnt
sudo mount -o subvol=/nix  /dev/mapper/cryptroot /mnt/nix
sudo mount -o subvol=/var-lib /dev/mapper/cryptroot /mnt/var/lib
sudo mount /dev/disk/by-partlabel/disk-main-ESP /mnt/boot
sudo nixos-enter --root /mnt
```

Reinstall the bootloader from inside `nixos-enter`:

```sh
NIXOS_INSTALL_BOOTLOADER=1 /run/current-system/bin/switch-to-configuration boot
```

## Network unlock stopped working

- **Tang unreachable:**
  - Is larkbox up and still at `192.168.178.190`?
  - On larkbox, check `systemctl status tangd.socket` and
    `tang-show-keys 7654`.
- **TPM refuses:**
  - PCR 7 changed (BIOS update, Secure Boot keys or enforcement). Unlock with
    the passphrase.
  - Then run `sudo network-unlock bind --replace`.
- **Tang keys lost or rotated:** same fix: passphrase, then `bind --replace`.
- **Header damaged:** `bind` wrote `/root/luks-header-*.bin` backups. Copy them
  off the box. Restore with
  `cryptsetup luksHeaderRestore <dev> --header-backup-file <file>`.

## Secure Boot fails

1. Disable enforcement in the BIOS via JetKVM.
2. Boot, restore `/var/lib/sbctl` if it is lost, and rebuild.
3. Re-enable enforcement.
4. Run `bind --replace`.

## Reinstalling the root disk

`tank` is untouched as long as only `_disko-nvme.nix` runs. In the same order as
[install.md](install.md):

1. Run `_disko-nvme.nix` only (new LUKS passphrase → KeePass).
2. Restore `/mnt/etc/zfs/keys/tank.key` from KeePass.
3. Generate a new initrd SSH host key in `/mnt/etc/secrets/initrd/`.
4. Restore `/mnt/var/lib/sbctl` if you have it. Otherwise re-enroll Secure Boot.
5. Run `nixos-install --flake .#homeserver --root /mnt`.
6. On first boot:
   - Re-add the sops recipient: the host key is new, so update `.sops.yaml` and
     run `sops updatekeys`.
   - Run `network-unlock bind`.

The pool imports automatically as long as `networking.hostId` is unchanged.

## Pre-install cleanup

If disko complains about old signatures on the NVMe, triple-check the device,
then run:

```sh
sudo wipefs -a /dev/disk/by-id/nvme-…
```
