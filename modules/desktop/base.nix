# Shared NixOS desktop plumbing used by Hyprland hosts.
{...}: {
  flake.modules.nixos.desktop-base = {pkgs, ...}: {
    # X11 keyboard configuration is also reused by the console.
    services.xserver.xkb = {
      layout = "us";
      options = "caps:escape";
    };
    console.useXkbConfig = true;

    # Audio with PipeWire.
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      wireplumber.extraConfig = {
        # Fix 1: prevent ALSA nodes from auto-suspending.
        # T2's apple-bce audio node doesn't reliably wake → internal speakers
        # only work at boot without this.
        "10-alsa-no-suspend" = {
          "monitor.alsa.rules" = [
            {
              matches = [{"node.name" = "~alsa_*";}];
              actions."update-props" = {
                "session.suspend-timeout-seconds" = 0;
                "node.pause-on-idle" = false;
              };
            }
          ];
        };

        # Fix 2: stable Bluetooth for Sony WH-1000XM6.
        # - Explicit codec list enables LDAC/AAC/SBC-XQ instead of library defaults.
        # - autoswitch-to-headset-profile = false keeps headphones in A2DP by default;
        #   the A2DP→HFP auto-switch on T2's BCM4377 caused a connect/disconnect loop.
        # - enable-msbc = false: XM6 only exposes CVSD for HFP anyway; being explicit
        #   avoids WirePlumber wasting time negotiating mSBC.
        # - Manual profile switching via `headphones-call` / `headphones-music` aliases.
        "11-bluetooth" = {
          "monitor.bluez.properties" = {
            "bluez5.roles" = ["a2dp_sink" "a2dp_source" "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag"];
            "bluez5.codecs" = ["sbc" "sbc_xq" "aac" "ldac" "aptx" "aptx_hd"];
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = false;
            "bluez5.enable-hw-volume" = true;
            "bluez5.hfphsp-backend" = "native";
          };
          "wireplumber.settings" = {
            "bluetooth.autoswitch-to-headset-profile" = false;
          };
        };
      };
    };
    security.rtkit.enable = true;

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
          UserspaceHID = true;
          AutoEnable = true;
          FastConnectable = true;
          ReconnectAttempts = 7;
          ReconnectIntervals = "1,2,4,8,16,32,64";
          JustWorksRepairing = "always";
          RememberPowered = true;
        };
        Policy.AutoEnable = true;
      };
    };
    services.blueman.enable = true;

    services.printing.enable = true;
    services.libinput.enable = true;

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    environment.sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      ELECTRON_ENABLE_WAYLAND = "1";
    };

    environment.systemPackages = with pkgs; [
      wl-clipboard
      cliphist
      brightnessctl
      networkmanagerapplet
      hyprmon
      mesa-demos
      libnotify
      grimblast
      satty
      grim
      slurp
      wl-screenrec
      hyprpicker
      playerctl
      swayosd
      nautilus
      gnome-calculator
      file-roller
      vlc
      polkit_gnome
      # PulseAudio CLI tools (pactl) for audio device/profile management.
      # Works against PipeWire's pulse compat layer.
      pulseaudio
    ];

    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
