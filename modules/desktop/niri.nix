# Niri window manager configuration
# NixOS and home-manager modules
{inputs, ...}: {
  flake.modules = {
    # Niri system configuration
    nixos.niri = {
      config,
      pkgs,
      username,
      ...
    }: {
      imports = [inputs.noctalia.nixosModules.default];

      programs.niri = {
        enable = true;
        useNautilus = true;
      };

      # Niri's package provides niri-session and its Wayland session entry.
      services.displayManager.defaultSession = "niri";
      programs.noctalia.enable = true;
      services.gnome.gnome-keyring.enable = true;

      # Niri needs the imported user-manager PATH rather than NixOS's stripped default.
      systemd.user.services.niri.enableDefaultPath = false;

      # Start the compositor selected by this host's desktop profile at login.
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --remember --asterisks --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
            user = "greeter";
          };
          initial_session = {
            command = "${config.programs.niri.package}/bin/niri-session";
            user = username;
          };
        };
      };

      users.users.greeter = {
        isNormalUser = false;
        description = "greetd greeter user";
        extraGroups = ["video" "audio"];
      };
    };

    # Home-manager Niri configuration
    homeManager.niri = {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }: let
      stylix = config.lib.stylix.colors.withHashtag;
      niri = lib.getExe pkgs.niri;
      noctalia = lib.getExe config.programs.noctalia.package;
      terminal = lib.getExe pkgs.wezterm;
      launcher = "${noctalia} msg panel-toggle launcher";
      lock = "${noctalia} msg session lock";

      startupScript = pkgs.writeShellScriptBin "niri-startup" ''
        ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator &
      '';

      regionScreenshot = pkgs.writeShellScriptBin "niri-region-screenshot" ''
        ${lib.getExe pkgs.grim} -g "$(${lib.getExe pkgs.slurp})" - | ${lib.getExe pkgs.satty} -f -
      '';

      saveBrightness = pkgs.writeShellScriptBin "niri-save-brightness" ''
        ${lib.getExe pkgs.brightnessctl} --save
      '';
      restoreBrightness = pkgs.writeShellScriptBin "niri-restore-brightness" ''
        ${lib.getExe pkgs.brightnessctl} --restore
      '';
      dimScreen = pkgs.writeShellScriptBin "niri-dim-screen" ''
        ${lib.getExe pkgs.brightnessctl} set 50%-
      '';
      powerOffMonitors = pkgs.writeShellScriptBin "niri-power-off-monitors" ''
        ${niri} msg action power-off-monitors
      '';
      powerOnMonitors = pkgs.writeShellScriptBin "niri-power-on-monitors" ''
        ${niri} msg action power-on-monitors
      '';
      suspend = pkgs.writeShellScriptBin "niri-suspend" ''
        systemctl suspend
      '';

      idleCommand =
        [
          (lib.getExe pkgs.swayidle)
          "-w"
          "timeout"
          "10"
          (lib.getExe saveBrightness)
          "resume"
          (lib.getExe restoreBrightness)
          "timeout"
          "30"
          (lib.getExe dimScreen)
          "timeout"
          "300"
          lock
          "timeout"
          "360"
          (lib.getExe powerOffMonitors)
          "resume"
          (lib.getExe powerOnMonitors)
          "before-sleep"
          lock
        ]
        ++ lib.optionals config.niri.suspendOnIdle [
          "timeout"
          "480"
          (lib.getExe suspend)
        ];
    in {
      imports = [inputs.noctalia.homeModules.default];

      options.niri.suspendOnIdle = lib.mkEnableOption "Suspend system after idle timeout" // {default = true;};

      config = {
        programs.noctalia = {
          enable = true;
          settings.wallpaper = {
            enabled = true;
            default.path = toString config.stylix.image;
          };
        };

        xdg.configFile."niri/config.kdl".text = ''
          input {
            keyboard {
              xkb {
                layout "us"
                options "ctrl:nocaps"
              }
              repeat-delay 300
              repeat-rate 50
            }
            touchpad {
              tap
              dwt
            }
            mouse {
              accel-profile "flat"
            }
            focus-follows-mouse
          }

          cursor {
            xcursor-theme "${config.stylix.cursor.name}"
            xcursor-size ${toString config.stylix.cursor.size}
          }

          layout {
            background-color "transparent"
            gaps 10
            focus-ring {
              width 2
              active-color "${stylix.base0D}"
              inactive-color "${stylix.base03}"
            }
            border {
              off
            }
          }

          overview {
            workspace-shadow {
              off
            }
          }

          layer-rule {
            match namespace="^noctalia-wallpaper"
            place-within-backdrop true
          }

          prefer-no-csd
          hotkey-overlay {
            skip-at-startup
          }

          debug {
            honor-xdg-activation-with-invalid-serial
          }

          xwayland-satellite {
            path "${lib.getExe pkgs.xwayland-satellite}"
          }

          spawn-at-startup "${lib.getExe startupScript}"
          spawn-at-startup "${noctalia}"

          window-rule {
            match app-id="^dev.noctalia.Noctalia$"
            open-floating true
            default-column-width { fixed 1080; }
            default-window-height { fixed 920; }
          }

          window-rule {
            match app-id="^firefox$" title="^Picture-in-Picture$"
            open-floating true
          }

          window-rule {
            match app-id="^org.gnome.Calculator$"
            open-floating true
          }

          binds {
            "Mod+Return" { spawn-sh "${terminal}"; }
            "Mod+D" { spawn-sh "${launcher}"; }
            "Mod+R" { spawn-sh "${launcher}"; }
            "Mod+S" { spawn-sh "${noctalia} msg panel-toggle control-center"; }
            "Mod+Comma" { spawn-sh "${noctalia} msg settings-toggle"; }
            "Alt+Tab" { spawn-sh "${noctalia} msg window-switcher"; }

            "Mod+Q" { close-window; }
            "Mod+F" { maximize-column; }
            "Mod+G" { fullscreen-window; }
            "Mod+Space" { toggle-window-floating; }
            "Mod+C" { center-column; }
            "Mod+Shift+E" { quit; }
            "Mod+Alt+L" { spawn-sh "${lock}"; }

            "Mod+H" { focus-column-left; }
            "Mod+J" { focus-window-down; }
            "Mod+K" { focus-window-up; }
            "Mod+L" { focus-column-right; }
            "Mod+Left" { focus-column-left; }
            "Mod+Right" { focus-column-right; }
            "Mod+Up" { focus-window-up; }
            "Mod+Down" { focus-window-down; }

            "Mod+Shift+H" { move-column-left; }
            "Mod+Shift+J" { move-window-down; }
            "Mod+Shift+K" { move-window-up; }
            "Mod+Shift+L" { move-column-right; }
            "Mod+Shift+Left" { move-column-left; }
            "Mod+Shift+Right" { move-column-right; }
            "Mod+Shift+Up" { move-window-up; }
            "Mod+Shift+Down" { move-window-down; }

            "Mod+Ctrl+H" { set-column-width "-5%"; }
            "Mod+Ctrl+L" { set-column-width "+5%"; }
            "Mod+Ctrl+J" { set-window-height "-5%"; }
            "Mod+Ctrl+K" { set-window-height "+5%"; }

            "Mod+Page_Down" { focus-workspace-down; }
            "Mod+Page_Up" { focus-workspace-up; }
            "Mod+BracketLeft" { focus-monitor-left; }
            "Mod+BracketRight" { focus-monitor-right; }

            "Mod+M" { focus-monitor-right; }
            "Mod+Shift+M" { move-column-to-monitor-right; }

            "Mod+1" { focus-workspace 1; }
            "Mod+2" { focus-workspace 2; }
            "Mod+3" { focus-workspace 3; }
            "Mod+4" { focus-workspace 4; }
            "Mod+5" { focus-workspace 5; }
            "Mod+6" { focus-workspace 6; }
            "Mod+7" { focus-workspace 7; }
            "Mod+8" { focus-workspace 8; }
            "Mod+9" { focus-workspace 9; }
            "Mod+0" { focus-workspace 10; }

            "Mod+Shift+1" { move-column-to-workspace 1; }
            "Mod+Shift+2" { move-column-to-workspace 2; }
            "Mod+Shift+3" { move-column-to-workspace 3; }
            "Mod+Shift+4" { move-column-to-workspace 4; }
            "Mod+Shift+5" { move-column-to-workspace 5; }
            "Mod+Shift+6" { move-column-to-workspace 6; }
            "Mod+Shift+7" { move-column-to-workspace 7; }
            "Mod+Shift+8" { move-column-to-workspace 8; }
            "Mod+Shift+9" { move-column-to-workspace 9; }
            "Mod+Shift+0" { move-column-to-workspace 10; }

            "Print" { spawn-sh "${lib.getExe regionScreenshot}"; }
            "Shift+Print" { screenshot-screen; }
            "Mod+Shift+S" { spawn-sh "${lib.getExe regionScreenshot}"; }
            "Mod+Shift+C" { spawn-sh "${noctalia} msg panel-toggle clipboard"; }

            "XF86AudioMute" allow-when-locked=true { spawn-sh "${noctalia} msg volume-mute"; }
            "XF86AudioRaiseVolume" allow-when-locked=true { spawn-sh "${noctalia} msg volume-up"; }
            "XF86AudioLowerVolume" allow-when-locked=true { spawn-sh "${noctalia} msg volume-down"; }
            "XF86AudioPlay" allow-when-locked=true { spawn-sh "${lib.getExe pkgs.playerctl} play-pause"; }
            "XF86AudioPause" allow-when-locked=true { spawn-sh "${lib.getExe pkgs.playerctl} play-pause"; }
            "XF86AudioNext" allow-when-locked=true { spawn-sh "${lib.getExe pkgs.playerctl} next"; }
            "XF86AudioPrev" allow-when-locked=true { spawn-sh "${lib.getExe pkgs.playerctl} previous"; }
            "XF86MonBrightnessUp" allow-when-locked=true { spawn-sh "${noctalia} msg brightness-up"; }
            "XF86MonBrightnessDown" allow-when-locked=true { spawn-sh "${noctalia} msg brightness-down"; }
          }
        '';

        services.playerctld.enable = true;

        systemd.user.services.niri-idle = {
          Unit = {
            Description = "Niri idle management";
            After = ["graphical-session.target"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            ExecStart = lib.escapeShellArgs idleCommand;
            Restart = "on-failure";
          };
          Install.WantedBy = ["graphical-session.target"];
        };

        # Match existing Hyprland desktop behavior for GNOME applications.
        dconf.settings."org/gnome/desktop/wm/preferences".button-layout = ":";
      };
    };
  };
}
