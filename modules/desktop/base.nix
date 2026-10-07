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
        # Bluetooth audio tuned for Sony WH-1000XM6.
        # - Explicit codec list enables LDAC/AAC/SBC-XQ instead of library defaults.
        # - autoswitch-to-headset-profile = true: WirePlumber switches to HFP when an
        #   app opens the headset mic and back to A2DP when it closes.
        # - enable-msbc = true: wideband (16 kHz) HFP for calls instead of 8 kHz CVSD.
        #   HFP codecs (msbc, lc3_swb) must also be in the codec list.
        "11-bluetooth" = {
          "monitor.bluez.properties" = {
            "bluez5.roles" = ["a2dp_sink" "a2dp_source" "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag"];
            "bluez5.codecs" = ["sbc" "sbc_xq" "aac" "ldac" "aptx" "aptx_hd" "msbc" "lc3_swb"];
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = true;
            "bluez5.enable-hw-volume" = true;
            "bluez5.hfphsp-backend" = "native";
          };
          "wireplumber.settings" = {
            "bluetooth.autoswitch-to-headset-profile" = true;
          };
        };
      };
    };
    security.rtkit.enable = true;

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      # Exposes headset battery level to UPower / desktop widgets.
      settings.General.Experimental = true;
    };
    services.blueman.enable = true;

    services.printing.enable = true;
    services.libinput.enable = true;

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    environment.sessionVariables = {
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
      swayidle
      xwayland-satellite
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
