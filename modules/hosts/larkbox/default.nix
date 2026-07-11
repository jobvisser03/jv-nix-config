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

    # ACTUAL ROOT-CAUSE FIX for the recurring hard hang (see NOTE below).
    # The crash is load-independent: it has struck during the 02:00 Immich
    # storm AND at ~idle while only playing a YouTube video in Firefox. Every
    # crash is an instantaneous full-power-loss hard hang - empty pstore, no
    # MCE/thermal/OOM/disk errors, and the RTC resets to a bogus date (the box
    # loses all power and needs a physical adapter reseat).
    #
    # Iteration 1 (DISPROVEN): capped intel_idle at C1E to kill the buggy deep
    # package C-states (kernel even flags "hpet: HPET dysfunctional in PC10").
    # The cap verifiably applied (only POLL/C1 remain) but the box STILL hard-
    # hung while playing a YouTube video -> CPU deep-idle is not the trigger.
    #
    # Iteration 2 (current): the surviving common thread across every crash is
    # the Intel media/display engine - YouTube uses VA-API video decode and the
    # 02:00 Immich storm uses Quick Sync transcode, both on i915. intel_idle
    # does not govern the GPU/display power states, which is why iteration 1
    # missed. Alder Lake-N is well known to hard-hang in the i915 display power
    # states (DMC/DC) and Panel Self Refresh; disabling them is the standard
    # mitigation and costs a headless-ish server nothing.
    boot.kernelParams = [
      "intel_idle.max_cstate=1" # keep: harmless, kills deep pkg C-states
      "i915.enable_dc=0" # disable display C-states (DMC/DC power wells)
      "i915.enable_psr=0" # disable Panel Self Refresh
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
    # The settings below (powersave governor + thermald + P-state cap) are kept
    # because they are harmless and slightly reduce the load spike, but they
    # are NOT the fix - see systemd.watchdog below for the actual mitigation.
    powerManagement.cpuFreqGovernor = lib.mkForce "performance";
    services.thermald.enable = true;

    systemd.services.intel-pstate-limit = {
      description = "Cap Intel P-state max turbo to 90 % (load-shaving, not the root fix)";
      wantedBy = ["multi-user.target"];
      after = ["systemd-modules-load.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        echo 90 > /sys/devices/system/cpu/intel_pstate/max_perf_pct
      '';
    };

    # Arm the N100's iTCO hardware watchdog. This is the real mitigation: the
    # crash is a hard hang with nothing logged, and today it requires a
    # physical adapter reseat to recover. With the watchdog armed, systemd
    # pets it from PID 1; if the box wedges hard enough that PID 1 can no
    # longer run, the hardware resets it automatically (~2 min) instead of
    # sitting dead until someone power-cycles it.
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
