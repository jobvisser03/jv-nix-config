# MacBook Intel running NixOS host definition
{...}: {
  flake.modules.nixos."hosts/macbook-intel-nixos" = {
    config,
    pkgs,
    lib,
    inputs,
    username,
    ...
  }: let
    # Patched apple-bce driver with internal suspend/resume support
    # Source: https://github.com/klizas/apple-bce-drv (branch: aur)
    # This eliminates the need for module unloading/reloading on suspend/resume
    appleBcePatched = pkgs.callPackage ./_apple-bce-patched.nix {
      kernel = config.boot.kernelPackages.kernel;
    };
  in {
    imports = [
      # Hardware configuration
      ./_hardware-configuration.nix
      ./_secrets.nix

      # T2 Mac suspend/resume fix
      ./_t2-suspend

      # Rclone module
      ../../_rclone
    ];

    # Host identity
    networking.hostName = "job-mac-nixos";

    # Boot configuration
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot";
      timeout = 0;
    };

    # Use patched apple-bce module with suspend/resume support
    # This replaces the built-in module from nixos-hardware
    boot.extraModulePackages = [appleBcePatched];

    # Blacklist the built-in apple-bce module to use our patched version
    boot.blacklistedKernelModules = ["apple-bce"];

    # Load our patched apple-bce module
    boot.kernelModules = ["apple-bce"];

    # Enable T2 suspend/resume fixes
    # This handles: PipeWire audio, apple-bce module unload/reload, WiFi, Bluetooth, Touch Bar
    hardware.apple-t2-suspend = {
      enable = true;
      keyboardBacklightLevel = 100;
      useDeepSleep = true;
      disableAspm = true; # Improves suspend stability
      unloadAppleBce = true; # Required for reliable resume
      stopAudio = true; # Release PipeWire handles before apple-bce unload
    };

    # Fix NetworkManager-wait-online failures
    systemd.services.NetworkManager-wait-online = {
      serviceConfig = {
        ExecStart = lib.mkForce "${pkgs.networkmanager}/bin/nm-online -s -q --timeout=10";
      };
    };

    # Apple T2 specific firmware
    hardware.firmware = [
      (pkgs.stdenvNoCC.mkDerivation (final: {
        name = "brcm-firmware";
        src = ./_firmware/brcm;
        installPhase = ''
          mkdir -p $out/lib/firmware/brcm
          cp ${final.src}/* "$out/lib/firmware/brcm"
        '';
      }))
    ];

    # Host-specific hardware settings
    hardware = {
      nvidia.modesetting.enable = false;
    };

    # Rclone cloud storage mounts
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
      };
    };

    # Disable Tailscale temporarily
    services.tailscale.enable = true;

    # Host-specific packages
    environment.systemPackages = with pkgs; [
      tree
    ];

    system.stateVersion = "25.05";
  };
}
