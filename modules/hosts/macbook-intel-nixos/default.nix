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

      # T2 Mac suspend/resume fix
      ./_t2-suspend

      # GPU mode (igpu/dgpu)
      ./_gpu.nix

      # Rclone module
      ../../_rclone
    ];

    macbook.gpuMode = "dgpu";

    # Host identity
    networking.hostName = "job-mac-nixos";

    # Boot configuration
    boot.loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 6;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot";
      timeout = 0;
    };

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

    # GPU-specific kernel params are managed by _gpu.nix based on gpuMode

    # Kernel modules for Docker networking
    boot.kernelModules = [ "br_netfilter" "bridge" "veth" ];

    # Docker systemd dependencies - just wait for NetworkManager, not network-online
    systemd.services.docker = {
      after = [ "NetworkManager.service" ];
      requires = [ "NetworkManager.service" ];
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # Disable NetworkManager-wait-online to avoid 60s+ startup delay on WiFi
    systemd.services.NetworkManager-wait-online.enable = false;

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

    # thermald disabled by _t2-suspend module (conflicts with T2 suspend)

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
         pcloud- = {
          remote = "pcloud:PHOTOS/'TEMP Photo Library'";
          mountpoint = "/home/${username}/pcloud/temp-photo-library";
          cacheMode = "writes";
          readOnly = false;
          uid = 1000;
          gid = 100;
        };     };
    };

    # Disable Tailscale temporarily
    services.tailscale.enable = true;
    
    # Printing
    services.printing = {
      enable = true;
      drivers = [ pkgs.splix ];
    };
 
    # Podman for OCI containers (Home Assistant, etc.)
    # virtualisation.podman = {
    #   enable = true;
    #   dockerCompat = true;
    #   autoPrune.enable = true;
    #   defaultNetwork.settings = {
    #     dns_enabled = true;
    #   };
    # };
    virtualisation.docker = {
      enable = true;
      daemon.settings = {
        userland-proxy = false;
        data-root = "/data/docker";
      };
    };

    # Use Podman as OCI backend
    virtualisation.oci-containers.backend = "docker";

    # ZSA Moonlander udev rules (for Keymapp/Wally flashing and live training)
    services.udev.extraRules = ''
      # Rules for Oryx web flashing and live training
      KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
      KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

      # Rule for the Moonlander
      SUBSYSTEM=="usb", ATTR{idVendor}=="3297", ATTR{idProduct}=="1969", GROUP="plugdev"

      # Keymapp / Wally Flashing rules for the Moonlander
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE:="0666", SYMLINK+="stm32_dfu"
    '';

    # Add user to plugdev group for ZSA keyboard access
    users.users.${username}.extraGroups = [ "plugdev" ];

    # Host-specific packages
    environment.systemPackages = with pkgs; [
      tree
    ];

    system.stateVersion = "25.05";
  };
}
