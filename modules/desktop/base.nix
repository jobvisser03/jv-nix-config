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
