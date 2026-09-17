# Framework Laptop 13 Pro host.
#
# This host intentionally keeps hardware policy separate from the shared
# laptop-hyprland profile. Replace _hardware-configuration.nix with the
# machine-generated file before installation.
{...}: {
  flake.modules.nixos."hosts/framework-13-pro" = {
    config,
    lib,
    pkgs,
    inputs,
    ...
  }: let
    persistenceDirectories = [
      "/etc/ssh"
      "/etc/NetworkManager/system-connections"
      "/var/lib/fprint"
      "/var/lib/NetworkManager"
      "/var/lib/nixos"
      "/var/lib/sbctl"
      "/var/lib/tailscale"
    ];
    persistenceFiles = [
      "/etc/machine-id"
      "/var/lib/systemd/random-seed"
    ];
    persistedDirectory = path:
      lib.any (
        entry:
          if builtins.isString entry
          then entry == path
          else entry.directory == path
      )
      config.environment.persistence."/persist".directories;
    persistedFile = path:
      lib.any (
        entry:
          if builtins.isString entry
          then entry == path
          else entry.file == path
      )
      config.environment.persistence."/persist".files;
    crypttabExtraOpts = ["tpm2-device=auto" "tpm2-pcrs=7"];
  in {
    imports = [
      ./_hardware-configuration.nix
      ./_disko.nix
      inputs.disko.nixosModules.disko
      inputs.impermanence.nixosModules.impermanence
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
    ];

    networking.hostName = "framework-13-pro";

    # Bootstrap without shared SOPS secrets. Enable after enrolling this
    # machine's SSH-derived age recipient and running sops updatekeys.
    llmSecrets.enable = false;

    # Lanzaboote replaces systemd-boot. Keys are generated and enrolled on
    # the installed laptop; /var/lib/sbctl is persisted below.
    boot.loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot";
      timeout = 3;
    };
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      # Initial installation runs with Secure Boot disabled. This service uses
      # sbctl to create keys on first boot; /var/lib/sbctl is persisted below.
      autoGenerateKeys.enable = true;
    };

    # systemd-initrd lets systemd-cryptsetup try the TPM2 token first and
    # fall back to an interactive LUKS passphrase prompt.
    boot.initrd.systemd.enable = true;
    boot.initrd.luks.devices.cryptroot.crypttabExtraOpts = crypttabExtraOpts;
    boot.resumeDevice = "/dev/vg/swap";

    # The root subvolume is reset before sysroot.mount. /home and /persist
    # are separate subvolumes and survive this reset.
    boot.initrd.systemd.services.rollback-root = {
      description = "Reset ephemeral BTRFS root subvolume";
      wantedBy = ["initrd.target"];
      after = [
        "systemd-cryptsetup@cryptroot.service"
        "dev-vg-root.device"
      ];
      before = ["sysroot.mount"];
      requires = ["dev-vg-root.device"];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      path = with pkgs; [
        btrfs-progs
        coreutils
        util-linux
      ];
      script = ''
        set -eu
        mkdir -p /mnt
        mount -t btrfs -o subvolid=5 /dev/vg/root /mnt
        if btrfs subvolume show /mnt/root >/dev/null 2>&1; then
          btrfs subvolume list -o /mnt/root | cut -f9- -d' ' | while read -r subvolume; do
            btrfs subvolume delete "/mnt/$subvolume"
          done
          btrfs subvolume delete /mnt/root
        fi
        btrfs subvolume create /mnt/root
        umount /mnt
      '';
    };

    # Impermanence needs persistent storage available before initrd and
    # local-fs activation create links into it. /nix is a separate persistent
    # subvolume, so root reset never removes the installed Nix store.
    fileSystems."/nix".neededForBoot = true;
    fileSystems."/persist".neededForBoot = true;

    environment.systemPackages = [pkgs.sbctl];

    environment.persistence."/persist" = {
      hideMounts = true;
      directories = persistenceDirectories;
      files = persistenceFiles;
    };

    assertions = [
      {
        assertion = config.fileSystems."/".fsType == "btrfs";
        message = "Framework root filesystem must use BTRFS.";
      }
      {
        assertion = lib.elem "subvol=/root" config.fileSystems."/".options;
        message = "Framework root filesystem must mount BTRFS subvolume root.";
      }
      {
        assertion = config.fileSystems."/home".fsType == "btrfs";
        message = "Framework home filesystem must use BTRFS.";
      }
      {
        assertion = lib.elem "subvol=/home" config.fileSystems."/home".options;
        message = "Framework home filesystem must mount BTRFS subvolume home.";
      }
      {
        assertion = config.fileSystems."/nix".fsType == "btrfs";
        message = "Framework Nix filesystem must use BTRFS.";
      }
      {
        assertion = lib.elem "subvol=/nix" config.fileSystems."/nix".options;
        message = "Framework Nix filesystem must mount BTRFS subvolume nix.";
      }
      {
        assertion = config.fileSystems."/nix".neededForBoot;
        message = "Framework Nix filesystem must be available during boot.";
      }
      {
        assertion = config.fileSystems."/persist".fsType == "btrfs";
        message = "Framework persistence filesystem must use BTRFS.";
      }
      {
        assertion = lib.elem "subvol=/persist" config.fileSystems."/persist".options;
        message = "Framework persistence filesystem must mount BTRFS subvolume persist.";
      }
      {
        assertion = config.fileSystems."/persist".neededForBoot;
        message = "Framework persistence filesystem must be available during boot.";
      }
      {
        assertion = config.disko.devices.disk.main.content.partitions.luks.content.content.type == "lvm_pv";
        message = "Framework LUKS container must contain the LVM physical volume.";
      }
      {
        assertion = config.disko.devices.lvm_vg.vg.lvs.root.content.type == "btrfs";
        message = "Framework LVM root logical volume must contain BTRFS.";
      }
      {
        assertion = config.disko.devices.lvm_vg.vg.lvs.swap.size == "40G";
        message = "Framework swap logical volume must be 40 GiB.";
      }
      {
        assertion = lib.any (swap: swap.device == "/dev/vg/swap") config.swapDevices;
        message = "Framework must have 40 GiB LVM swap device.";
      }
      {
        assertion = config.boot.resumeDevice == "/dev/vg/swap";
        message = "Framework hibernation must resume from LVM swap.";
      }
      {
        assertion = config.boot.lanzaboote.enable;
        message = "Framework must use Lanzaboote for Secure Boot.";
      }
      {
        assertion = config.boot.lanzaboote.autoGenerateKeys.enable;
        message = "Framework must generate Secure Boot keys with sbctl during initial installation.";
      }
      {
        assertion = !config.boot.loader.systemd-boot.enable;
        message = "Framework must disable the stock systemd-boot module when Lanzaboote is enabled.";
      }
      {
        assertion = config.boot.initrd.systemd.enable;
        message = "Framework TPM2 LUKS unlock requires systemd-based initrd.";
      }
      {
        assertion = config.boot.initrd.luks.devices.cryptroot.crypttabExtraOpts == crypttabExtraOpts;
        message = "Framework LUKS unlock must use TPM2 PCR 7 with passphrase fallback.";
      }
      {
        assertion = persistedDirectory "/etc/ssh";
        message = "Framework SSH host keys must persist across root resets.";
      }
      {
        assertion = persistedFile "/etc/machine-id";
        message = "Framework NixOS machine identity must persist across root resets.";
      }
      {
        assertion = persistedDirectory "/var/lib/NetworkManager";
        message = "Framework NetworkManager state must persist across root resets.";
      }
      {
        assertion = persistedFile "/var/lib/systemd/random-seed";
        message = "Framework systemd random seed must persist across root resets.";
      }
      {
        assertion = persistedDirectory "/var/lib/sbctl";
        message = "Framework Secure Boot signing keys must persist outside the ephemeral root.";
      }
    ];

    system.stateVersion = "25.11";
  };
}
