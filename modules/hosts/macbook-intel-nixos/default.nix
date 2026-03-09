# MacBook Intel running NixOS host definition
{...}: {
  flake.modules.nixos."hosts/macbook-intel-nixos" = {
    config,
    pkgs,
    lib,
    inputs,
    username,
    ...
  }: {
    imports = [
      # Hardware configuration
      ./_hardware-configuration.nix
      ./_secrets.nix

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
        src = ./firmware/brcm;
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
