# Niri window manager configuration
# NixOS and home-manager modules
{inputs, ...}: {
  flake.modules = {
    # Niri system configuration
    nixos.niri = {
      config,
      pkgs,
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

      # No autologin: the password typed at tuigreet lets greetd's PAM stack
      # unlock gnome-keyring, so apps don't prompt for the keyring password.
      services.greetd = {
        enable = true;
        useTextGreeter = true;
        settings.default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --remember --remember-user-session --asterisks --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
          user = "greeter";
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
      handyToggle = "${lib.getExe inputs.handy.packages.${pkgs.system}.handy} --toggle-transcription";

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

      kiosk = config.niri.mediaKiosk.enable;
      firefox = lib.getExe config.programs.firefox.finalPackage;
      gaps =
        if kiosk
        then "0"
        else "10";
      defaultColumnWidth =
        if kiosk
        then "1.000000"
        else "0.500000";
      cornerRadius =
        if kiosk
        then "0"
        else "15";

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

      options.niri = {
        suspendOnIdle = lib.mkEnableOption "Suspend system after idle timeout" // {default = true;};

        # Couch/beamer media node: edge-to-edge windows, Firefox at login,
        # hidden idle cursor, and no lock/dim/blank while watching video.
        mediaKiosk.enable = lib.mkEnableOption "media kiosk layout for full-HD beamer playback";
      };

      config = {
        programs.noctalia = {
          enable = true;
          settings.wallpaper = {
            enabled = true;
            directory = "~/Pictures/Wallpapers";
            default.path = toString config.stylix.image;
          };
          # Wallhaven browser: downloads into wallpaper.directory and applies it.
          settings.plugins.enabled = ["noctalia/wallhaven"];
        };

        # Seed the picker with the repo wallpapers; the dir itself stays
        # writable so Wallhaven downloads land next to them.
        home.file."Pictures/Wallpapers/nix-wallpaper-binary-black.png".source = ../../non-nix-configs/nix-wallpaper-binary-black.png;
        home.file."Pictures/Wallpapers/nixos-wallpaper-catppuccin-frappe.png".source = ../../non-nix-configs/nixos-wallpaper-catppuccin-frappe.png;

        # https://github.com/niri-wm/niri/blob/main/resources/default-config.kdl
        xdg.configFile."niri/config.kdl".text = ''
          input {
            keyboard {
              xkb {
                layout "us"
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
            ${lib.optionalString kiosk "hide-when-typing"}
            ${lib.optionalString kiosk "hide-after-inactive-ms 3000"}
          }

          layout {
            background-color "transparent"
            gaps ${gaps}
            focus-ring {
              ${lib.optionalString kiosk "off"}
              width 2
              active-color "${stylix.base0D}"
              inactive-color "${stylix.base03}"
            }
            border {
              off
            }
            default-column-width { proportion ${defaultColumnWidth}; }
            preset-column-widths {
                proportion 0.333330
                proportion 0.500000
                proportion 0.666670
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
          ${lib.optionalString kiosk ''spawn-at-startup "${firefox}"''}

          window-rule {
            // Rounded corners for a modern look; square edges on the beamer.
            geometry-corner-radius ${cornerRadius}

            // Clips window contents to the rounded corner boundaries.
            clip-to-geometry true
          }

          window-rule {
            match app-id="^dev.noctalia.Noctalia$"
            open-floating true
            default-column-width { fixed 1080; }
            default-window-height { fixed 920; }
          }

          ${lib.optionalString kiosk ''
            window-rule {
              match app-id="^firefox$"
              open-maximized true
            }
          ''}

          window-rule {
            match app-id="^firefox$" title="^Picture-in-Picture$"
            open-floating true
          }

          window-rule {
            match app-id="^org.gnome.Calculator$"
            open-floating true
          }

          // Handy's recording overlay is an xdg-toplevel, not a layer surface;
          // keep it from stealing focus so the transcript lands in the right window.
          window-rule {
            match app-id=r#"^Handy$"# title="^Recording$"
            open-floating true
            open-focused false
            focus-ring { off; }
            shadow { off; }
          }

          binds {
            "Mod+Return" { spawn-sh "${terminal}"; }
            "Mod+D" { spawn-sh "${launcher}"; }
            "Mod+S" { spawn-sh "${noctalia} msg panel-toggle control-center"; }
            "Mod+Comma" { spawn-sh "${noctalia} msg settings-toggle"; }
            "Alt+Tab" { spawn-sh "${noctalia} msg window-switcher"; }

            "Mod+O" repeat=false { toggle-overview; }

            "Mod+Q" repeat=false { close-window; }
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

            // The following binds move the focused window in and out of a column.
            // If the window is alone, they will consume it into the nearby column to the side.
            // If the window is already in a column, they will expel it out.
            Mod+BracketLeft  { consume-or-expel-window-left; }
            Mod+BracketRight { consume-or-expel-window-right; }

            "Mod+Shift+H" { move-column-left; }
            "Mod+Shift+J" { move-window-down; }
            "Mod+Shift+K" { move-window-up; }
            "Mod+Shift+L" { move-column-right; }
            "Mod+Shift+Left" { move-column-left; }
            "Mod+Shift+Right" { move-column-right; }
            "Mod+Shift+Up" { move-window-up; }
            "Mod+Shift+Down" { move-window-down; }

            // Cycle through widths set in preset-column-widths.
            Mod+R { switch-preset-column-width; }
            // Cycling through the presets in reverse order is also possible.
            Mod+Shift+R { switch-preset-column-width-back; }

            Mod+U              { focus-workspace-down; }
            Mod+I              { focus-workspace-up; }
            Mod+Ctrl+U         { move-column-to-workspace-down; }
            Mod+Ctrl+I         { move-column-to-workspace-up; }


            Mod+Ctrl+Right { focus-monitor-right; }
            Mod+Ctrl+H     { focus-monitor-left; }
            Mod+Ctrl+J     { focus-monitor-down; }
            Mod+Ctrl+K     { focus-monitor-up; }
            Mod+Ctrl+L     { focus-monitor-right; }

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
            "Alt+Space" { spawn-sh "${handyToggle}"; }

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

        # Firefox inhibits idle only while video plays; a paused stream must
        # not lock or blank the beamer, so the kiosk skips idle management.
        systemd.user.services.niri-idle = lib.mkIf (!kiosk) {
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
