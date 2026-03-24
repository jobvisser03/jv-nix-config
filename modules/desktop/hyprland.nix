# Hyprland window manager configuration
# NixOS and home-manager module
{...}: {
  flake.modules = {
    # NixOS hyprland system configuration
    nixos.hyprland = {
      pkgs,
      lib,
      config,
      username,
      ...
    }: {
      # Enable Hyprland at system level
      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };

      # XDG Portal configuration for Hyprland
      xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-hyprland
        ];
        config = {
          common = {
            default = ["hyprland" "gtk"];
          };
          hyprland = {
            default = ["hyprland" "gtk"];
          };
        };
      };

      # Required services for desktop
      services = {
        # Display manager
        displayManager.defaultSession = "hyprland-uwsm";

        # Greetd display manager with auto-login
        greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --remember --asterisks --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
              user = "greeter";
            };
            # Auto-login for the primary user
            initial_session = {
              command = "uwsm start hyprland-uwsm.desktop";
              user = username;
            };
          };
        };

        # X11 keyboard configuration (used by console)
        xserver.xkb = {
          layout = "us";
          options = "caps:escape";
        };
      };

      # Console uses xkb config
      console.useXkbConfig = true;

      # Audio with PipeWire
      services.pulseaudio.enable = false;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
      security.rtkit.enable = true;

      # Bluetooth
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            Experimental = true;
            UserspaceHID = true; # Helps with high-resolution scrolling/input
          };
        };
      };
      services.blueman.enable = true;

      # Printing
      services.printing.enable = true;

      # Touchpad
      services.libinput.enable = true;

      # Graphics
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      # Wayland environment variables
      environment.sessionVariables = {
        WLR_NO_HARDWARE_CURSORS = "1";
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        ELECTRON_ENABLE_WAYLAND = "1";
      };

      # Desktop packages
      environment.systemPackages = with pkgs; [
        # Wayland utilities
        wl-clipboard
        cliphist
        brightnessctl
        networkmanagerapplet
        hyprmon

        # GPU utility to check which GPU is rendering a window
        mesa-demos

        # Notifications (dunst configured via home-manager dunst module)
        libnotify

        # Screenshot & recording
        grimblast
        satty
        grim
        slurp
        wl-screenrec

        # Color picker
        hyprpicker

        # Media control
        playerctl

        # On-screen display
        swayosd

        # File manager
        nautilus

        # Desktop utilities
        gnome-calculator
        file-roller
        vlc

        # Polkit agent
        polkit_gnome
      ];

      # Polkit authentication agent
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

      # Create greeter user
      users.users.greeter = {
        isNormalUser = false;
        description = "greetd greeter user";
        extraGroups = ["video" "audio"];
      };
    };

    # Home-manager hyprland configuration
    homeManager.hyprland = {
      pkgs,
      lib,
      config,
      ...
    }: let
      # Startup script - waybar is started by systemd, so don't include it here
      startupScript = pkgs.writeShellScriptBin "start" ''
        ${pkgs.swww}/bin/swww-daemon &
        wl-paste --type text --watch cliphist store &
        wl-paste --type image --watch cliphist store &
        nm-applet --indicator &
      '';
      rgb = color: "rgb(${color})";
      stylix = config.lib.stylix.colors;
    in {
      wayland.windowManager.hyprland = {
        enable = true;
        package = pkgs.hyprland;
        systemd.enable = false; # UWSM handles systemd session management
        systemd.enableXdgAutostart = true;

        settings = {
          exec-once = [
            "${startupScript}/bin/start"
            "wpctl set-mute @DEFAULT_AUDIO_SINK@ 1"
            "swayosd-server"
          ];

          misc = {
            disable_splash_rendering = true;
            disable_hyprland_logo = true;
            allow_session_lock_restore = true;
            vfr = true;
            animate_manual_resizes = true;
            focus_on_activate = true;
          };

          monitorv2 = [
            {
              output = "";
              mode = "preferred";
              position = "auto";
              scale = "1.60";
            }
            {
              output = "eDP-1";
              mode = "3072x1920";
              position = "512x1344";
              scale = "1.60";
            }
            {
              output = "DP-6";
              mode = "3840x1600";
              position = "0x0";
              scale = "1.25";
            }
            {
              # Disable phantom dGPU output (AMD eDP-2)
              output = "eDP-2";
              disabled = true;
            }
          ];

          xwayland = {
            force_zero_scaling = true;
          };

          render = {
            new_render_scheduling = true;
          };

          input = {
            kb_layout = "us";
            kb_options = "ctrl:nocaps";
            follow_mouse = 1;
            sensitivity = 0;
            repeat_delay = 300;
            repeat_rate = 50;
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
            layout = "scrolling";
            resize_on_border = false;
            allow_tearing = true;
          };

          decoration = {
            rounding = 10;
            active_opacity = config.stylix.opacity.applications;
            inactive_opacity = lib.mkIf (config.stylix.opacity.applications < 1) (
              config.stylix.opacity.applications - 0.2
            );
            fullscreen_opacity = 1.0;
            blur = {
              enabled = true;
              size = 4;
              passes = 2;
            };
            shadow = {
              enabled = true;
              range = 30;
            };
          };

          scrolling = {
            column_width = 0.5;
            focus_fit_method = 1; # 0 = center, 1 = fit
            follow_focus = true;
            fullscreen_on_one_column = true;
            # wrap_focus = true;
            # wrap_swapcol = true;
          };

          master = {
            new_status = "master";
          };

          cursor = {
            no_hardware_cursors = false;
            use_cpu_buffer = true;
          };

          animation = [
            "fade, 1, 4, default"
            "border, 1, 2, default"
            "windows, 1, 3, default, slide"
            "workspaces, 1, 2, default, slide"
          ];

          group = lib.mkForce {
            "col.border_active" = rgb stylix.base0D;
            "col.border_inactive" = rgb stylix.base03;
            "col.border_locked_active" = rgb stylix.base0C;
            "col.border_locked_inactive" = rgb stylix.base0B;
            groupbar = {
              text_color = rgb stylix.base00;
              font_size = config.stylix.fonts.sizes.desktop;
              height = builtins.floor (config.stylix.fonts.sizes.desktop * 1.5 + 0.5);
              indicator_height = 0;
              rounding = 10;
              gradients = true;
              gradient_rounding = 10;
            };
          };

          workspace = [
            "1, monitor:eDP-1, default:true"
            "2, monitor:eDP-1, default:true"
            "3, monitor:eDP-1, default:true"
            # Smart Gaps
            "w[tv1], gapsout:0, gapsin:0"
            "f[1], gapsout:0, gapsin:0"
            # Special workspaces
            "special:spotify, on-created-empty:spotify"
            "special:spotify, gapsout:50"
            "special:monitor, on-created-empty:wezterm btop"
            "special:monitor, gapsout:50"
            "special:logseq, on-created-empty:logseq"
            "special:logseq, gapsout:50"
          ];

          "$mod" = "SUPER";
          "$floatingSize" = "600 400";

          bindd =
            [
              # Submaps
              "SUPER, A, Activate applications submap, submap, applications"
              "SUPER, S, Activate system submap, submap, system"

              # Open applications
              "SUPER, RETURN, Open terminal, exec, wezterm"
              ", XF86Calculator, Open calculator, exec, gnome-calculator"

              # Tiling controls
              "SUPER, Q, Close focused window, killactive"
              "SUPER, F, Fullscreen focused window, fullscreen"
              "SUPER, W, Toggle floating, togglefloating"
              "SUPER, P, Pin focused window, pin"

              # Window grouping
              "SUPER, G, Toggle group, togglegroup"
              "SUPER ALT, G, Move out of group, moveoutofgroup"
              "SUPER SHIFT, G, Lock or unlock active group, lockactivegroup, toggle"
              "SUPER ALT, H, Move window to group on left, movewindoworgroup, l"
              "SUPER ALT, J, Move window to group on bottom, movewindoworgroup, d"
              "SUPER ALT, K, Move window to group on top, movewindoworgroup, u"
              "SUPER ALT, L, Move window to group on right, movewindoworgroup, r"
              "SUPER, TAB, Change active window in group right, changegroupactive, f"
              "SUPER SHIFT, TAB, Change active window in group left, changegroupactive, b"

              # Scrolling layout controls
              "SUPER, I, Promote window to own column, layoutmsg, promote"
              "SUPER, bracketleft, Cycle column width down, layoutmsg, colresize -conf"
              "SUPER, bracketright, Cycle column width up, layoutmsg, colresize +conf"
              "SUPER SHIFT, F, Fit all columns to screen, layoutmsg, fit all"
              "SUPER, equal, Toggle fit/center mode, layoutmsg, togglefit"

              # Move window focus
              "SUPER, H, Focus column to the left, layoutmsg, focus l"
              "SUPER, J, Focus window below in column, layoutmsg, focus d"
              "SUPER, K, Focus window above in column, layoutmsg, focus u"
              "SUPER, L, Focus column to the right, layoutmsg, focus r"

              # Move/swap columns
              "SUPER SHIFT, H, Swap column left, layoutmsg, swapcol l"
              "SUPER SHIFT, J, Move window down in column, swapwindow, d"
              "SUPER SHIFT, K, Move window up in column, swapwindow, u"
              "SUPER SHIFT, L, Swap column right, layoutmsg, swapcol r"

              # Resize column
              "SUPER CTRL, H, Decrease column width, layoutmsg, colresize -0.05"
              "SUPER CTRL, L, Increase column width, layoutmsg, colresize +0.05"

              # Launcher
              "SUPER, D, Open application launcher, exec, rofi -show drun"
              "SUPER, R, Open application launcher, exec, rofi -show drun"

              # Screenshot (Print key for quick region screenshot)
              ", Print, Screenshot region, exec, grimblast --freeze save area - | satty -f -"
              "SHIFT, Print, Screenshot fullscreen, exec, grimblast --freeze save screen"

              # Clipboard
              "SUPER SHIFT, C, Show clipboard history, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"

              # Workspace switching
              "SUPER, Prior, Switch to next workspace, workspace, r-1"
              "SUPER, Next, Switch to previous workspace, workspace, r+1"
              "SUPER, mouse_down, Switch to next workspace, workspace, e+1"
              "SUPER, mouse_up, Switch to previous workspace, workspace, e-1"
            ]
            ++ (builtins.concatLists (
              builtins.genList (
                i: let
                  ws = i + 1;
                in [
                  "SUPER, code:1${toString i}, Switch to workspace ${toString ws}, workspace, ${toString ws}"
                  "SUPER SHIFT, code:1${toString i}, Move focused window to workspace ${toString ws}, movetoworkspace, ${toString ws}"
                ]
              )
              9
            ));

          bindl = [
            # Audio control (swayosd for visual feedback)
            ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
            ", XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"
            # Media controls
            ", XF86AudioPlay, exec, playerctl play-pause"
            ", XF86AudioPause, exec, playerctl play-pause"
            ", XF86AudioNext, exec, playerctl next"
            ", XF86AudioPrev, exec, playerctl previous"
          ];

          bindel = [
            # Volume control (swayosd for visual feedback)
            ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
            ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
            # Brightness control (swayosd for visual feedback)
            ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
            ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
          ];

          # Alt+Arrow → Ctrl+Arrow (macOS-style word navigation)
          bind = [
            "ALT, Left, sendshortcut, CTRL, Left, activewindow"
            "ALT, Right, sendshortcut, CTRL, Right, activewindow"
          ];

          binddm = [
            "SUPER, mouse:272, Move window with Super and left click, movewindow"
            "SUPER, mouse:273, Resize window with Super and right click, resizewindow"
          ];

          windowrule = [
            # Inhibit idle when fullscreen
            "match:fullscreen true, idle_inhibit always"

            # Smart Gaps
            "match:workspace w[tv1] s[false], match:float false, border_size 0, rounding 0, no_shadow true"
            "match:workspace f[1] s[false], match:float false, border_size 0, rounding 0"
            "match:workspace f[f1] s[false], match:float false, no_shadow true"

            # Fix some dragging issues with XWayland
            "match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false, no_focus true"

            # Ignore maximize requests from apps
            "match:class .*, suppress_event maximize"

            # Move apps to workspaces
            "match:class ^(spotify)$, workspace special:spotify silent"
            "match:class ^(Logseq)$, workspace special:logseq silent"

            # Dim some programs
            "match:class ^(xdg-desktop-portal-gtk)$, dim_around true"
            "match:class ^(polkit-gnome-authentication-agent-1)$, dim_around true"

            # NetworkManager applet
            "match:class ^(nm-connection-editor)$, float true, size $floatingSize, center true"

            # Blueman
            "match:class ^(.blueman-manager-wrapped)$, float true, size $floatingSize, center true"

            # Audio control
            "match:class ^(com.saivert.pwvucontrol)$, float true, size $floatingSize, center true"

            # Make some windows floating and sticky
            "match:title ^(Picture-in-Picture)$, float true, pin true"

            # Calculator
            "match:class ^(org.gnome.Calculator)$, float true, size > >"

            # Clock
            "match:class ^(org.gnome.clocks)$, float true, size 800 600"

            # Screenshot editor
            "match:class ^(com.gabm.satty)$, float true, opaque true"

            # Emulator
            "match:class ^(Emulator)$, float true, opaque true"
          ];

          layerrule =
            [
              "match:namespace ^(rofi|launcher)$, animation slide, dim_around true"
              "match:namespace ^(notifications)$, animation slide right"
            ]
            ++ lib.optional (config.stylix.opacity.desktop != 1.0) [
              "match:namespace ^(waybar|rofi|launcher|notifications)$, blur true, ignore_alpha 0"
            ];
        };

        extraConfig = ''
          # Applications submap (SUPER+A, then one key)
          submap = applications
          bindd = , B, Open browser, exec, firefox
          bindd = , E, Open file manager, exec, nautilus
          bindd = , N, Open notes (Logseq), togglespecialworkspace, logseq
          bindd = , M, Toggle monitor (btop), togglespecialworkspace, monitor
          bindd = , S, Toggle Spotify, togglespecialworkspace, spotify
          bindr = , catchall, submap, reset
          submap = reset

          # System submap (SUPER+S, then one key)
          submap = system
          bindd = , S, Screenshot region (edit), exec, grimblast --freeze save area - | satty -f -
          bindd = SHIFT, S, Screenshot fullscreen, exec, grimblast --freeze save screen
          bindd = , R, Start/stop screen recording, exec, pkill wl-screenrec || wl-screenrec -f ~/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4
          bindd = , C, Color picker, exec, hyprpicker -a
          bindd = , L, Lock screen, exec, loginctl lock-session
          bindde = , equal, Zoom in, exec, hyprctl keyword cursor:zoom_factor "$(hyprctl getoption cursor:zoom_factor | grep float | awk '{print $2 + 0.5}')"
          bindde = , minus, Zoom out, exec, hyprctl keyword cursor:zoom_factor "$(hyprctl getoption cursor:zoom_factor | grep float | awk '{print ($2 - 0.5 < 1) ? 1 : $2 - 0.5}')"
          bindd = SHIFT, minus, Reset zoom, exec, hyprctl keyword cursor:zoom_factor 1
          bindr = , catchall, submap, reset
          submap = reset
        '';
      };

      # Playerctl daemon for media key integration
      services.playerctld.enable = true;

      # Copy scripts for hyprlock
      home.file.".config/hypr/scripts" = {
        source = ../../modules/_wm-scripts;
        recursive = true;
      };

      # Gnome button layout
      dconf.settings = {
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "':'";
        };
      };
    };
  };
}
