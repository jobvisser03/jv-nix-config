# Larkbox homelab server host definition
# NixOS server with homelab services
{...}: {
  flake.modules.nixos."hosts/larkbox" = {
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
    networking.hostName = "larkbox";

    # Enable sudo for wheel group members
    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    # Boot configuration
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Keep deep CPU and iGPU display power states disabled while diagnosing the
    # recurring hard power loss. The latest crash happened during a CPU-heavy
    # Nix build, so i915 is not established as the root cause. The inability to
    # power on normally afterwards points to power delivery, EC, or firmware.
    boot.kernelParams = [
      "intel_idle.max_cstate=1"
      "i915.enable_dc=0"
    ];

    # Firewall configuration - allow local network and Tailscale
    networking.firewall = {
      enable = true;
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = [41641];
    };

    # Tailscale VPN - enable server routing features for homelab
    services.tailscale.useRoutingFeatures = "server";

    # Desktop mode power management
    powerManagement.desktopMode = true;
    hardware.graphics.enable = true;

    # NOTE on the recurring "sudden shutdown" bug (Intel N100, fanless):
    # The thermal hypothesis was DISPROVEN by measurement. Under a real
    # all-core AVX x264 software transcode this box peaks at only ~63 °C and
    # ~10 W package power - nowhere near the 110 °C hardware cutoff. There are
    # also zero OOM events, zero USB/exfat/disk errors, no MCE, and an empty
    # pstore across every crash boot. The failure is an instantaneous hard
    # hang (black screen, unresponsive power button, fsck dirty-bit on the
    # next boot) that always lands inside the 02:00 Immich job storm (library
    # scan of ~83 k files over the rclone/pcloud FUSE mounts + transcode + ML).
    # The only kernel artifact ever captured was Immich threads stuck 122 s in
    # D-state in vfs_statx on those FUSE paths -> an I/O/FUSE stall, not a
    # resource/thermal limit.
    #
    # Minimize sustained package and VRM load while hardware power delivery is
    # investigated. max_perf_pct limits P-state, not CPU utilization or watts.
    powerManagement.cpuFreqGovernor = lib.mkForce "powersave";
    services.thermald.enable = true;

    systemd.services.intel-pstate-limit = {
      description = "Disable turbo and cap Intel P-state performance to 60 %";
      wantedBy = ["multi-user.target"];
      after = ["systemd-modules-load.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
        echo 60 > /sys/devices/system/cpu/intel_pstate/max_perf_pct
      '';
    };

    # Reduce concurrent Nix build load while diagnosing hard power loss.
    nix.settings = {
      max-jobs = 2;
      cores = 2;
    };

    # Arm the N100's iTCO hardware watchdog. This can recover a kernel or
    # userspace hang, but cannot recover a latched power or EC fault.
    systemd.watchdog = {
      runtimeTime = "20s"; # iTCO_wdt heartbeat is 30 s; stay under it
      rebootTime = "10min"; # force reset if a clean reboot itself hangs
    };

    # Hardware error logging (MCE / PCIe AER / thermal events) persisted to
    # /var/lib/rasdaemon/ras-mc_event.db so we can diagnose the next
    # unexpected power-off / hard hang after reboot.
    hardware.rasdaemon.enable = true;

    # Homelab services
    homelab = {
      enable = true;
      services.enable = true;
      services.enableReverseProxy = true;
      services.enablePublicHttps = true;

      domain = "dutchdataworks.nl";

      services.forgejo.enable = true;
      services.gitlab.enable = false;
      services.gitlab-runner.enable = false;
      services.jellyfin.enable = false;

      services.immich = {
        enable = true;
        externalLibraryDirs = [
          "/mnt/usb-drive/PHOTOS-PCLOUD"
          "/mnt/usb-drive/SMARTPHONE-PHOTOS-PCLOUD"
        ];
      };

      services.homepage.enable = true;

      services.radicale = {
        enable = false;
        passwordFile = config.sops.secrets.radicale_htpasswd.path;
      };

      services.paperless = {
        enable = true;
        passwordFile = config.sops.secrets.paperless_admin_password.path;
      };

      services.homeassistant = {
        enable = true;
        zigbee2mqtt = {
          enable = true;
          usbDevice = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_34bde4cea845ed1184b8d18f0a86e0b4-if00-port0";
        };
        mosquitto.enable = true;
      };

      services.spotify-player = {
        enable = true;
      };

      services.remote-pi-relay = {
        enable = true;
      };

      services.cloudflare-ddns = {
        enable = true;
        zoneId = "8d43a62314697fa92a98e8b77e771434";
        recordName = "homelab.dutchdataworks.nl";
        tokenFile = config.sops.secrets.cloudflare_ddns_token.path;
      };
    };

    # Rclone cloud storage mounts
    services.rclone = {
      enable = true;
      configFile = config.sops.secrets.rclone_config.path;
      mounts = {
        pcloud-photos = {
          remote = "pcloud:PHOTOS";
          mountpoint = "/mnt/usb-drive/PHOTOS-PCLOUD";
          cacheMode = "minimal";
          readOnly = true;
          requiredMounts = ["/mnt/usb-drive"];
        };
        pcloud-smartphone-photos = {
          remote = "pcloud:'Automatic Upload'";
          mountpoint = "/mnt/usb-drive/SMARTPHONE-PHOTOS-PCLOUD";
          cacheMode = "minimal";
          readOnly = true;
          requiredMounts = ["/mnt/usb-drive"];
        };
        pcloud-keepass = {
          remote = "pcloud:keepass-vault";
          mountpoint = "/home/${username}/pcloud/keepass-vault";
          cacheMode = "writes";
          readOnly = false;
          uid = 1000;
          gid = 100;
        };
      };
    };

    environment.systemPackages = with pkgs; [
      apacheHttpd
    ];

    # Home-manager overrides for this host
    home-manager.users.${username} = {
      # Disable suspend on idle for homelab server
      hypridle.suspendOnIdle = false;
    };

    system.stateVersion = "25.11";
  };
}
