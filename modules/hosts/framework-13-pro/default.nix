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
    crypttabExtraOpts = ["tpm2-device=auto" "tpm2-pcrs=7"];
  in {
    imports = [
      ./_hardware-configuration.nix
      ./_disko.nix
      inputs.disko.nixosModules.disko
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
    ];

    networking.hostName = "framework-13-pro";

    # Bootstrap without shared SOPS secrets. Enable after enrolling this
    # machine's SSH-derived age recipient and running sops updatekeys.
    llmSecrets.enable = false;

    # Lanzaboote replaces systemd-boot. Keys are generated and enrolled on
    # the installed laptop; /var/lib/sbctl remains on the normal root filesystem.
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
      # sbctl to create keys on first boot; /var/lib/sbctl remains on root.
      autoGenerateKeys.enable = true;
    };

    # systemd-initrd lets systemd-cryptsetup try the TPM2 token first and
    # fall back to an interactive LUKS passphrase prompt.
    boot.initrd.systemd.enable = true;
    boot.initrd.luks.devices.cryptroot.crypttabExtraOpts = crypttabExtraOpts;
    boot.resumeDevice = "/dev/vg/swap";

    environment.systemPackages = [pkgs.sbctl];

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
    ];

    system.stateVersion = "25.11";
  };
}
