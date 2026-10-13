# Framework Laptop 13 Pro host.
#
# This host intentionally keeps hardware policy separate from its desktop
# profile. Select laptop-niri or laptop-hyprland in configurations.nix.
# Replace _hardware-configuration.nix with the machine-generated file before installation.
{...}: {
  flake.modules.nixos."hosts/framework-13-pro" = {
    config,
    lib,
    pkgs,
    inputs,
    username,
    ...
  }: {
    imports = [
      ./_hardware-configuration.nix
      ./_disko.nix
      ../../_rclone
      inputs.disko.nixosModules.disko
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
    ];

    networking.hostName = "framework-13-pro";
    home-manager.users.${username}.programs.obsidian.vaults.notes.target = lib.mkForce "syncthing/obsidian_vault";

    # Use power-profiles-daemon so Noctalia can switch Framework power modes.
    services.tlp.enable = lib.mkForce false;
    services.power-profiles-daemon.enable = lib.mkForce true;

    # fprintd adds fingerprint auth to PAM (sudo, polkit); Noctalia's lock screen
    # talks to fprintd directly. Keep the greeter password-only so greetd can
    # still unlock gnome-keyring.
    services.fprintd.enable = true;
    security.pam.services.greetd.fprintAuth = false;

    # The shared SOPS file includes this host's ssh-to-age recipient.
    # sops-nix decrypts it at activation using /etc/ssh/ssh_host_ed25519_key.
    llmSecrets.enable = true;

    sops.secrets.rclone_config = {
      sopsFile = ../../../secrets/shared.yaml;
      owner = "root";
      group = "root";
      mode = "0400";
      path = "/run/secrets/rclone.conf";
    };

    services.rclone = {
      enable = true;
      configFile = config.sops.secrets.rclone_config.path;
      mounts = {
        pcloud-keepass = {
          remote = "pcloud:keepass-vault";
          mountpoint = "/home/${username}/pcloud/keepass-vault";
          cacheMode = "writes";
          readOnly = false;
          uid = 1000;
          gid = 100;
        };
        pcloud-persoonlijk-job = {
          remote = "pcloud:'Persoonlijk Job'";
          mountpoint = "/home/${username}/pcloud/persoonlijk-job";
          cacheMode = "writes";
          readOnly = false;
          uid = 1000;
          gid = 100;
        };
        pcloud-temp-photo-library = {
          remote = "pcloud:PHOTOS/'TEMP Photo Library'";
          mountpoint = "/home/${username}/pcloud/temp-photo-library";
          cacheMode = "writes";
          readOnly = false;
          uid = 1000;
          gid = 100;
        };
        pcloud-data-mastery = {
          remote = "pcloud:'DATA MASTERY'";
          mountpoint = "/home/${username}/pcloud/data-mastery";
          cacheMode = "writes";
          readOnly = false;
          uid = 1000;
          gid = 100;
        };
        pcloud-dutch-dataworks = {
          remote = "pcloud:'DUTCH DATAWORKS'";
          mountpoint = "/home/${username}/pcloud/dutch-dataworks";
          cacheMode = "writes";
          readOnly = false;
          uid = 1000;
          gid = 100;
        };
      };
    };

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

    # LUKS unlocks unattended only at home: TPM2 (PCR 7) AND a Tang server on
    # the LAN, reached over Wi-Fi from the initrd. Elsewhere it asks for the
    # passphrase. See docs/network-unlock.md.
    networkUnlock = {
      enable = true;
      tpm2Pcrs = "7";
      wifi = {
        enable = true;
        interface = "wlp0s20f3";
      };
      # Intel Wi-Fi 7 (8086:e440) uses the iwlmld op-mode. Its ucode is not in
      # iwlwifi's modinfo list, so name the file the kernel actually loads
      # (`journalctl -k -b | grep 'loaded firmware'`).
      initrdKernelModules = ["iwlwifi" "iwlmld"];
      initrdFirmware = ["iwlwifi-sc-a0-wh-b0-101.ucode"];
      # Enable once homeserver is installed and serving Tang (`bind` needs every
      # listed server reachable), then run `network-unlock bind --replace`:
      # tangServers = ["http://192.168.178.190:7654" "http://192.168.178.43:7654"];
    };
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
        assertion = config.networkUnlock.enable && config.boot.initrd.clevisLuksAskpass.enable;
        message = "Framework LUKS unlock must use Clevis Tang + TPM2 with passphrase fallback.";
      }
    ];

    system.stateVersion = "25.11";
  };
}
