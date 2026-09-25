# Framework Laptop 13 Pro

NixOS host for Framework Laptop 13 Pro with Intel Core Ultra X7 358H, integrated Intel graphics, and one internal NVMe drive.

> **Install warning:** disko formatting is destructive. Do not run disko format mode until device path, backups, and generated hardware configuration are verified.

## Design

- Host: `framework-13-pro`
- Profile: exact `laptop-hyprland` profile used by `macbook-intel-nixos`
- Hardware: generic checked-in template plus `nixos-hardware.nixosModules.framework-intel-core-ultra-series3`
- Boot: UEFI, Lanzaboote, Secure Boot, `sbctl`
- Encryption: LUKS2 with TPM2 PCR 7 unlock and passphrase fallback
- Storage: GPT → 1 GiB ESP → LUKS2 → LVM → BTRFS
- BTRFS subvolumes: `/root`, `/home`, `/nix`
- Swap: 40 GiB LVM LV for 32 GiB RAM and hibernation
- Persistent root filesystem: `/root`, `/home`, and `/nix` survive reboots

## Before installation

1. Confirm target NVMe device and capacity. Device must fit 1 GiB ESP, 40 GiB swap, encrypted LVM/BTRFS, and user data.
2. Boot a NixOS installer in UEFI mode.
3. Keep Secure Boot disabled or in firmware setup mode during initial installation.
4. Clone this repository and inspect:

   ```sh
   readlink -f /dev/disk/by-id/*nvme*
   sed -n '1,220p' modules/hosts/framework-13-pro/_disko.nix
   ```

5. Replace `nvme-FRAMEWORK-13-PRO-REPLACE-ME` in `_disko.nix` with the target's stable `/dev/disk/by-id` path.
6. Replace generic hardware data after disko mounts the target. Do not commit filesystem UUIDs or device data from another machine.

## Installation

Run from repository root. Commands below can erase the selected NVMe.

```sh
# Preview target and configuration first.
ls -l /dev/disk/by-id/
nix flake check
nix eval --raw .#nixosConfigurations.framework-13-pro.config.disko.devices.disk.main.device

# Destructive: create GPT, ESP, LUKS2, LVM, BTRFS, and swap.
sudo nix run github:nix-community/disko -- --mode disko --flake .#framework-13-pro

# Mount generated filesystems.
sudo nix run github:nix-community/disko -- --mode mount --flake .#framework-13-pro

# Generate machine-specific initrd and hardware data.
sudo nixos-generate-config --no-filesystems --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix \
  modules/hosts/framework-13-pro/_hardware-configuration.nix

# Re-evaluate after replacing the template, then install.
nix eval .#nixosConfigurations.framework-13-pro.config.system.build.toplevel.drvPath
sudo nixos-install --flake .#framework-13-pro --root /mnt
```

The generic template contains safe NVMe/initrd defaults only. Generated output is authoritative for PCI, USB, storage, and platform-specific hardware details.

## SOPS

NixOS uses `/etc/ssh/ssh_host_ed25519_key` as its system identity. `sops-nix` converts it to the matching age identity at activation via `sops.age.sshKeyPaths` in `modules/base/sops.nix`. The `&framework_13_pro` recipient in `.sops.yaml` and `secrets/shared.yaml` must remain an age recipient produced by `ssh-to-age`; do not use SOPS native SSH recipients, which derive a different identity.

The host recipient is enrolled for sops-nix activation via `sops.age.sshKeyPaths`; bare `sops` uses Framework's personal age identity in `~/.config/sops/age/keys.txt`. Its public recipient is `&framework_user` in `.sops.yaml`. All four hosts have separate personal editing identities; NixOS host-key recipients remain for activation. Do not commit private identities or decrypted secrets.

LLM secrets and shared `rclone_config` live in `secrets/shared.yaml`. Framework consumes `rclone_config` through sops-nix and mounts the same pCloud paths as Mac Intel NixOS. Larkbox keeps its homelab service secrets in `secrets/larkbox.yaml` and reads `rclone_config` from `shared.yaml`.

From the repository root, edit normally:

```sh
sops secrets/shared.yaml
sops secrets/larkbox.yaml
```

Changing `.sops.yaml` alone does not update existing ciphertext. Run `sops updatekeys` on each retained encrypted file while an identity in its current metadata can decrypt it; then confirm proposed recipient changes.

Verify Framework decryption:

```sh
sudo nixos-rebuild switch --flake .#framework-13-pro
sudo systemctl status sops-install-secrets.service
sudo test -s /run/secrets/openai_api_key
```

## Secure Boot

Private Secure Boot keys must stay outside Git and outside backups that are not protected like passwords. Lanzaboote reads its key bundle from `/var/lib/sbctl`; that directory is persisted by this host.

Initial installation permits unsigned artifacts while Secure Boot is disabled. On first boot, `boot.lanzaboote.autoGenerateKeys` runs `sbctl create-keys` and writes keys to `/var/lib/sbctl`. If the service did not run, create them manually:

```sh
sudo sbctl create-keys
sudo sbctl status
```

Rebuild once keys exist. Lanzaboote then signs boot artifacts with `/var/lib/sbctl`.

1. Put Framework firmware into Secure Boot setup mode. In **Administer Secure Boot**, delete PK, KEK, and DB entries one at a time. Do not choose **Erase all Secure Boot Settings**.
2. Enroll keys while preserving vendor certificates:

   ```sh
   sudo sbctl enroll-keys --microsoft --firmware-builtin
   sudo sbctl verify
   bootctl status
   ```

3. Enable **Enforce Secure Boot** in Framework firmware and reboot.
4. Confirm `bootctl status` reports `Secure Boot: enabled (user)`.

Back up `/var/lib/sbctl` securely. If keys are lost, restore them before rebuilding boot artifacts. If firmware keys or Secure Boot policy change, re-enroll TPM2 unlock with PCR 7 using the LUKS passphrase first.

## TPM2 LUKS unlock

The initrd uses systemd-cryptsetup. It tries the TPM2 token bound to PCR 7 and then presents the LUKS passphrase prompt when TPM unlock fails.

After first boot, enroll the TPM token against the LUKS partition. Replace the device path with the exact path shown by `lsblk -f`:

```sh
lsblk -f
sudo systemd-cryptenroll \
  --tpm2-device=auto \
  --tpm2-pcrs=7 \
  /dev/disk/by-id/nvme-FRAMEWORK-13-PRO-REPLACE-ME-part2
sudo systemd-cryptenroll \
  /dev/disk/by-id/nvme-FRAMEWORK-13-PRO-REPLACE-ME-part2
```

The second command lists enrolled slots. Store and test the LUKS passphrase before relying on TPM unlock. Re-enroll the TPM token after:

- Secure Boot keys change.
- Secure Boot enforcement or firmware policy changes.
- Firmware updates change PCR 7 measurements.
- TPM is cleared or replaced.

Do not remove the passphrase slot. TPM unlock is convenience, not recovery.

## Persistence

No impermanence reset runs on this host. `/root`, `/home`, and `/nix` are ordinary persistent BTRFS subvolumes. All system state, passwords, SSH host keys, NetworkManager state, and Secure Boot keys remain across reboot.

Verify after installation:

```sh
sudo touch /root/framework-13-pro-persistence-test
sudo reboot
sudo test -e /root/framework-13-pro-persistence-test
```

User data belongs in `/home`; system state remains under `/etc` and `/var` as normal NixOS state.

## Hibernation acceptance

The host declares a 40 GiB encrypted LVM swap LV and resume device for 32 GiB RAM. After installation:

```sh
swapon --show
cat /proc/cmdline
systemctl hibernate
```

Verify that the laptop powers off, resumes into the same session, and retains data. Test both TPM unlock and passphrase fallback after cold boot. Do not mark hibernation complete until resume works with Secure Boot enabled.

## Non-destructive validation

Run from a Linux builder or installed NixOS system:

```sh
nix flake check
nix eval .#nixosConfigurations.framework-13-pro.config.system.build.toplevel.drvPath
nix build .#nixosConfigurations.framework-13-pro.config.system.build.toplevel --no-link
nix eval --raw .#nixosConfigurations.framework-13-pro.config.disko.devices.disk.main.device
nix eval --json .#nixosConfigurations.framework-13-pro.config.fileSystems
```

These commands do not format disks. Do not use `--mode disko` outside installation or a disposable test disk.

## QA checklist

- [ ] Replace disko device placeholder with intended NVMe by-id path.
- [ ] Replace generic hardware template with generated `--no-filesystems` output.
- [ ] Verify `/`, `/home`, and `/nix` subvolume mounts.
- [ ] Reboot and confirm `/nix/store` remains available.
- [ ] Confirm Framework host recipient in `.sops.yaml` and `secrets/shared.yaml` match.
- [ ] Verify host-key-based `sops updatekeys` workflow when recipient list changes.
- [ ] Rebuild and verify `/run/secrets/openai_api_key`.
- [ ] Test TPM unlock and passphrase fallback.
- [ ] Test Secure Boot enforcement and hibernation resume.

## Recovery

If replacing an existing impermanent installation, prefer clean reinstall after backing up `/home`. Existing installs may contain `/etc` and `/var` symlinks into the old `/persist` tree; an in-place install needs manual state migration.

From USB installer for clean reinstall:

```sh
# Clone updated repo, verify device and backups first.
git clone <repo-url> /tmp/jv-nix-config
cd /tmp/jv-nix-config
nix flake check

# Destructive: recreates target disk without /persist.
sudo nix run github:nix-community/disko -- --mode disko --flake .#framework-13-pro
sudo nix run github:nix-community/disko -- --mode mount --flake .#framework-13-pro
sudo nixos-generate-config --no-filesystems --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix \
  modules/hosts/framework-13-pro/_hardware-configuration.nix
sudo nixos-install --flake .#framework-13-pro --root /mnt
sudo nixos-enter --root /mnt -c 'passwd job'
```

`nixos-install` prompts for root password. Set `job` password from `nixos-enter`; do not commit `initialPassword` or password hashes. Keep Secure Boot disabled during initial install. If preserving current disk, mount existing `/root`, `/home`, `/nix`, and `/boot`, run only `nixos-install` (not disko), then migrate old `/persist` state before reboot.

- **TPM unlock fails:** enter LUKS passphrase. Re-enroll TPM after confirming Secure Boot and PCR 7 state.
- **Secure Boot fails:** disable enforcement temporarily or return firmware to setup mode, boot a recovery generation, restore `/var/lib/sbctl`, and rebuild Lanzaboote artifacts.
- **Bootloader repair from live media:** mount target filesystems, enter the installation, and run:

  ```sh
  sudo nixos-enter --root /mnt
  NIXOS_INSTALL_BOOTLOADER=1 /run/current-system/bin/switch-to-configuration boot
  ```

- **Wrong disk path:** stop before running disko. Edit `_disko.nix`, verify `/dev/disk/by-id`, and re-run only against intended device.
- **Bad generated hardware file:** restore the checked-in generic template or regenerate with `nixos-generate-config --no-filesystems`; never copy another machine's UUIDs.
