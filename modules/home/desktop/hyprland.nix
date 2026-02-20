# Hyprland window manager - home-manager configuration
{lib, ...}: {
  flake.modules.home.hyprland = {
    config,
    pkgs,
    ...
  }: let
    startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
      ${pkgs.waybar}/bin/waybar &
      ${pkgs.hypridle}/bin/hypridle &
      wl-paste --type text --watch cliphist store &
      wl-paste --type image --watch cliphist store &
      nm-applet --indicator &
    '';
  in {
    wayland.windowManager.hyprland = {
      systemd.enable = false;
      enable = true;
      package = null;
      portalPackage = null;
      extraConfig = ''
        bind = , Print, exec, grim -g "$(slurp)" - | wl-copy | dunstify "Screenshot of the region copied" -t 1000 # screenshot of a region
        	bind = SUPER, Print, exec, grim -g "$(slurp)" - | wl-copy && wl-paste > ~/Pictures/Screenshots/Screenshot-$(date +%F_%T).png | dunstify "Screenshot of whole screen saved" -t 1000 # screenshot of the whole screen
      '';
      settings = {
        exec-once = [
          "${startupScript}/bin/start"
        ];

        misc = {
          disable_splash_rendering = true;
          disable_hyprland_logo = true;
        };

        # MONITOR
        monitor = [
          ", preferred, auto, 1.33"
          "HDMI-A-1,preferred,auto, 1, mirror, eDP-1"
        ];

        xwayland = {
          force_zero_scaling = true;
        };

        # KEYBOARD AND TOUCHPAD
        input = {
          kb_layout = "us";
          kb_options = "caps:swapescape";
          follow_mouse = 1;
          touchpad = {
            tap-and-drag = true;
            natural_scroll = false;
          };
          sensitivity = 0.7;
          repeat_delay = 300;
          repeat_rate = 50;
          accel_profile = "adaptive";
        };

        env = [
          "ELECTRON_OZONE_PLATFORM_HINT,auto"
          "ELECTRON_ENABLE_WAYLAND,1"
        ];

        ecosystem = {
          no_donation_nag = true;
        };

        # GENERAL
        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          layout = "dwindle";
        };

        # DECORATION
        decoration = {
          rounding = 5;
          active_opacity = 0.99;
          inactive_opacity = 0.9;
          fullscreen_opacity = 0.9;
          blur = {
            enabled = false;
            size = 8;
            passes = 2;
            new_optimizations = true;
          };
          shadow = {
            enabled = false;
            range = 15;
            ignore_window = true;
            render_power = 3;
          };
        };

        # ANIMATIONS
        animations = {
          enabled = true;
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 2, myBezier"
            "windowsOut, 1, 2, default, popin 80%"
            "border, 1, 3, default"
            "fade, 1, 2, default"
            "workspaces, 1, 1, default"
          ];
        };

        # MASTER
        master = {
          new_status = "master";
        };

        # DWINDLE
        dwindle = {
          pseudotile = true;
          preserve_split = true;
          smart_split = true;
        };

        # BINDS
        "$mod" = "SUPER";

        bind = [
          # PROGRAM BINDS
          "$mod, Q, exec, kitty"
          "$mod, T, exec, kitty"
          "$mod, C, killactive"
          "$mod, M, exit"
          "$mod, E, exec, nautilus"
          "$mod, F, exec, firefox"
          "$mod SHIFT, F, togglefloating"
          "$mod, R, exec, rofi -show drun"
          "$mod, D, exec, rofi -show drun"
          "$mod, J, togglesplit, #dwindle"
          "$mod SHIFT, Q, exit"

          # MOVEFOCUS
          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"

          # WORKSPACE
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"
          "$mod, 0, workspace, 10"

          # ACTIVE WORKSPACE
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"
          "$mod SHIFT, 0, movetoworkspace, 10"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        windowrule = [
          "opaque on, match:class ^(Emulator)$"
          "float on, match:class ^(Emulator)$"
        ];
      };
    };
  };
}
