# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # Common system modules
    ../../modules/system

    # Profiles
    ../../profiles/default.nix

    # Docker services
    ../../docker-services/docker-compose.nix
  ];

  # Host-specific configuration
  networking.hostName = "job-mac-nixos";

  # Time zone
  time.timeZone = "Europe/Amsterdam";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";

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

  # Network configuration
  networking.networkmanager.enable = true;

  virtualisation.docker = {
    enable = true;
    # Set up resource limits
    daemon.settings = {
      experimental = true;
      default-address-pools = [
        {
          base = "172.30.0.0/16";
          size = 24;
        }
      ];
    };
  };

  # Host-specific hardware settings
  hardware = {
    # Disable nvidia modesetting for this host
    nvidia.modesetting.enable = false;
  };

  # Define user account specific to this host
  users.users.job = {
    isNormalUser = true;
    extraGroups = ["wheel" "video" "audio" "networkmanager"];
    packages = with pkgs; [
      tree
    ];
    shell = pkgs.zsh;
  };

  # Host-specific greetd initial session
  services.greetd.settings.initial_session = {
    command = "${pkgs.hyprland}/bin/Hyprland";
    user = "job";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "25.05"; # Did you read the comment?
}
