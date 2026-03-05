{pkgs, lib, config, ...}: let
  startupScript = pkgs.writeShellScriptBin "start" ''
    ${pkgs.waybar}/bin/waybar &
    ${pkgs.hypridle}/bin/hypridle &
    wl-paste --type text --watch cliphist store &
    wl-paste --type image --watch cliphist store &
    nm-applet --indicator &
  '';
in
{
  wayland.windowManager.hyprland = {
    systemd.enable = false;
    enable = true;
    package = null;
    portalPackage = null;

    settings = {
      exec-once = [
        "${startupScript}/bin/start"
        "uwsm finalize"
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 1"
      ];

      misc = {
        disable_splash_rendering = true;
        disable_hyprland_logo = true;
        allow_session_lock_restore = true;
        vfr = true;
        animate_manual_resizes = true;
        focus_on_activate = true;
        allow_tearing = true;
      };

      monitorv2 = [
        {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = "1";
        }
      ];

      xwayland = {
        force_zero_scaling = true;
      };

      input = {
        kb_layout = "us";
        kb_options = "caps:swapescape";
        follow_mouse = 1;
        sensitivity = 0;
        scroll_method = "2fg";
        touchpad = {
          disable_while_typing = true;
          tap_button_map = "lrm";
          tap-to-click = true;
          tap-and-drag = true;
          natural_scroll = false;
        };
      };

      gestures = {
        workspace_swipe_invert = false;
        workspace_swipe_direction_lock = false;
        workspace_swipe_forever = true;
        workspace_swipe_use_r = true;
      };

      gesture = [
        "3, horizontal, workspace"
        "4, down, dispatcher, exec, loginctl lock-session"
      ];

      env = [
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "ELECTRON_ENABLE_WAYLAND,1"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
        resize_on_border = false;
        allow_tearing = true;
      };

      decoration = {
        rounding = 7;
        active_opacity = 0.95;
        inactive_opacity = 0.75;
        fullscreen_opacity = 1.0;
        blur = {
          enabled = true;
          size = 4;
          passes = 2;
          new_optimizations = true;
          ignore_opacity = false;
        };
        shadow = {
          enabled = true;
          range = 30;
          render_power = 2;
          ignore_window = false;
        };
      };

      dwindle = {
        pseudotile = true;
        preserve_split = false;
      };

      master = {
        new_status = "master";
      };

      scrolling = {
        column_width = "0.5";
        focus_fit_method = 1;
        explicit_column_widths = "0.333333, 0.5, 0.666667";
        follow_min_visible = 0.4;
      };

      cursor = {
        no_hardware_cursors = false;
        use_cpu_buffer = true;
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "fade, 1, 4, default"
          "border, 1, 2, default"
          "windows, 1, 3, default, slide"
          "workspaces, 1, 2, default, slide"
        ];
      };

      group = {
        "col.border_active" = "rgb(89b4fa)";
        "col.border_inactive" = "rgb(45475a)";
        "col.border_locked_active" = "rgb(74c7ec)";
        "col.border_locked_inactive" = "rgb(f5c2e7)";
      };

      workspace = [
        "1, monitor:eDP-1, default:true"
        "2, monitor:eDP-1, default:true"
        "3, monitor:eDP-1, default:true"
      ];

      "$mod" = "SUPER";

      bind = [
        "SUPER, A, Activate applications submap, submap, applications"
        "SUPER, RETURN, Open terminal, exec, kitty"
        "SUPER, E, Open terminal file manager, exec, nautilus"
        ", XF86Calculator, Open calculator, exec, gnome-calculator"

        "SUPER, S, Activate system submap, submap, system"

        "SUPER, C, killactive"
        "SUPER, M, exit"
        "SUPER, F, exec, firefox"
        "SUPER SHIFT, F, togglefloating"
        "SUPER, R, exec, rofi -show drun"
        "SUPER, D, exec, rofi -show drun"
        "SUPER, J, togglesplit"
        "SUPER SHIFT, Q, exit"

        "SUPER, left, movefocus, l"
        "SUPER, right, movefocus, r"
        "SUPER, up, movefocus, u"
        "SUPER, down, movefocus, d"

        "SUPER, Prior, Switch to next workspace, workspace, r-1"
        "SUPER, Next, Switch to previous workspace, workspace, r+1"
        "SUPER, mouse_down, Switch to next workspace, workspace, e+1"
        "SUPER, mouse_up, Switch to previous workspace, workspace, e-1"

        "SUPER, code:11, Switch to workspace 1, workspace, 1"
        "SUPER, code:12, Switch to workspace 2, workspace, 2"
        "SUPER, code:13, Switch to workspace 3, workspace, 3"
        "SUPER, code:14, Switch to workspace 4, workspace, 4"
        "SUPER, code:15, Switch to workspace 5, workspace, 5"
        "SUPER, code:16, Switch to workspace 6, workspace, 6"
        "SUPER, code:17, Switch to workspace 7, workspace, 7"
        "SUPER, code:18, Switch to workspace 8, workspace, 8"
        "SUPER, code:19, Switch to workspace 9, workspace, 9"

        "SUPER SHIFT, code:11, Move focused window to workspace 1, movetoworkspace, 1"
        "SUPER SHIFT, code:12, Move focused window to workspace 2, movetoworkspace, 2"
        "SUPER SHIFT, code:13, Move focused window to workspace 3, movetoworkspace, 3"
        "SUPER SHIFT, code:14, Move focused window to workspace 4, movetoworkspace, 4"
        "SUPER SHIFT, code:15, Move focused window to workspace 5, movetoworkspace, 5"
        "SUPER SHIFT, code:16, Move focused window to workspace 6, movetoworkspace, 6"
        "SUPER SHIFT, code:17, Move focused window to workspace 7, movetoworkspace, 7"
        "SUPER SHIFT, code:18, Move focused window to workspace 8, movetoworkspace, 8"
        "SUPER SHIFT, code:19, Move focused window to workspace 9, movetoworkspace, 9"
      ];

      submaps = {
        applications = {
          onDispatch = "reset";
          settings.bindd = [
            ", B, Open browser, exec, firefox"
            ", E, Open file manager, exec, nautilus"
            ", N, Open notes, exec, obsidian"
            ", M, Toggle monitor workspace, togglespecialworkspace, monitor"
            ", T, Toggle todo workspace, togglespecialworkspace, todo"
            ", S, Toggle Spotify workspace, togglespecialworkspace, spotify"
            ", D, Toggle Discord workspace, togglespecialworkspace, discord"
          ];
          settings.bindr = [ ", catchall, submap, reset" ];
        };
        system = {
          onDispatch = "reset";
          settings.bindd = [
            ", R, Start/stop screencast, exec, hyprcast"
            ", O, Copy text from screen, exec, wl-ocr -nc"
            ", C, Open color picker, exec, hyprpicker -a"
          ];
          settings.bindde = [
            ", plus, Zoom in, exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float * 1.1')"
            ", minus, Zoom out, exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '(.float * 0.9) | if . < 1 then 1 else . end')"
          ];
          settings.bindr = [ ", catchall, submap, reset" ];
        };
      };

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      windowrule = [
        "opaque on, match:class ^(Emulator)$"
        "float on, match:class ^(Emulator)$"
        "match:fullscreen true, idle_inhibit always"
        "match:class ^(nm-connection-editor)$, float true, size 600 400, center true"
        "match:class ^(.blueman-manager-wrapped)$, float true, size 600 400, center true"
        "match:class ^(com.saivert.pwvucontrol)$, float true, size 600 400, center true"
        "match:title ^(Picture-in-Picture)$, float true, pin true"
        "match:class ^(org.gnome.Calculator)$, float true, size > >"
        "match:class ^(org.gnome.clocks)$, float true, size 800 600"
        "match:class .*, suppress_event maximize"
      ];

      windowrulev2 = [
        "float 0, title:^(Picture-in-Picture)$"
      ];

      layerrule = [
        "blur, rofi"
        "blur, waybar"
        "animation slide, notifications"
      ];

      workspace = [
        "special:spotify, on-created-empty:spotify"
        "special:discord, on-created-empty:vesktop"
        "special:todo, on-created-empty:lunatask"
        "special:monitor, on-created-empty:kitty btop"
      ];
    };
  };
}
