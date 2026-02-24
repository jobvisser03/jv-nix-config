# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  inputs,
  username,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # Common NixOS configuration (shared with larkbox)
    ../common/nixos

    # Common system modules
    ../../modules/system

    # Profiles
    ../../profiles/default.nix

    # Secrets management
    ../../modules/sops
    ./secrets.nix

    # Standalone rclone for cloud storage mounts
    ../../modules/rclone
  ];

  # Host-specific configuration
  networking.hostName = "job-mac-nixos";

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    # grub.enable = true;
    # grub.device = "nodev";
    # grub.useOSProber = true;
    # grub.efiSupport = true;
    # Not working because macos EFI/APPLE/BOOT/BOOTX64.EFI doesn't exists
    # because macos hides this in it's onw partition and preboot config
    # TODO use rEFInd
    # grub.extraEntries = ''
    #   menuentry "macOS" {
    #     insmod hfsplus
    #     set root=(hd0,1)
    #     multiboot /boot
    #   }
    # '';
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
    timeout = 0;
  };

  # Apple T2 specific firmware
  hardware.firmware = [
    (pkgs.stdenvNoCC.mkDerivation (final: {
      name = "brcm-firmware";
      src = ./firmware/brcm;
      installPhase = ''
        mkdir -p $out/lib/firmware/brcm
        cp ${final.src}/* "$out/lib/firmware/brcm"
      '';
    }))
  ];

  # Host-specific hardware settings
  hardware = {
    # Disable nvidia modesetting for this host
    nvidia.modesetting.enable = false;
  };

  # Rclone cloud storage mounts (standalone module)
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
        remote = "pcloud:Persoonlijk Job";
        mountpoint = "/home/${username}/pcloud/persoonlijk-job";
        cacheMode = "writes";
        readOnly = false;
        uid = 1000;
        gid = 100;
      };
    };
  };

  # Host-specific user packages
  users.users.${username}.packages = with pkgs; [
    tree
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "25.05"; # Did you read the comment?
}
