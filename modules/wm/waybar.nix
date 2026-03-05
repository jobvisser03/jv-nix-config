{config, lib, pkgs, ...}: let
  stylix = config.lib.stylix.colors.withHashtag;
  borderRadius = "10";
  borderSize = "2";
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        spacing = 0;
        reload_style_on_change = true;

        modules-left = [
          "custom/actions"
          "hyprland/workspaces"
          "hyprland/window"
        ];

        modules-center = [
          "privacy"
          "clock"
        ];

        modules-right = [
          "hyprland/submap"
          "backlight"
          "wireplumber"
          "group/power"
          "group/hardware"
          "tray"
        ];

        "custom/actions" = {
          format = "";
          tooltip-format = "System Actions";
          on-click = "rofi -show drun";
        };

        "hyprland/workspaces" = {
          show-special = true;
          special-visible-only = true;
          format = "{icon}";

          format-icons = {
            "discord" = "";
            "todo" = "";
            "monitor" = "󰍹";
            "obsidian" = "";
            "spotify" = "";
            "default" = "";
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
          };

          persistent-workspaces = {
            "*" = 5;
          };
        };

        "hyprland/window" = {
          max-length = 50;
          format = "{title}";
          icon = true;
        };

        privacy = {
          icon-spacing = 4;
          icon-size = 18;
          transition-duration = 250;
        };

        clock = {
          format = " {:%A %H:%M}";

          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "month";
            weeks-pos = "left";
            mode-mon-col = 3;
            format = {
              months = "<span color='${stylix.base06}'><b>{}</b></span>";
              days = "<span color='${stylix.base05}'><b>{}</b></span>";
              weeks = "<span color='${stylix.base0E}'><b>W{}</b></span>";
              weekdays = "<span color='${stylix.base0A}'><b>{}</b></span>";
              today = "<span color='${stylix.base0B}'><b><u>{}</u></b></span>";
            };
          };

          actions = {
            on-click-right = "mode";
            on-click-middle = "shift_reset";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };

        "hyprland/submap" = {
          format = "󰧹 {}";
        };

        backlight = {
          format = "{icon}";
          format-icons = [
            "󱩎"
            "󱩏"
            "󱩐"
            "󱩑"
            "󱩒"
            "󱩓"
            "󱩔"
            "󱩕"
            "󱩖"
            "󰛨"
          ];
          tooltip-format = "{percent}%";
        };

        wireplumber = {
          format = "{icon}";
          format-muted = "󰝟";
          format-icons = [
            "󰕿"
            "󰖀"
            "󰕾"
          ];
          tooltip-format = "{volume}% on {node_name}";
          on-click = lib.getExe pkgs.pwvucontrol;
          on-click-right = "${lib.getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };

        "group/power" = {
          orientation = "inherit";

          drawer = {
            transition-duration = 300;
            transition-left-to-right = false;
          };

          modules = [
            "battery"
            "idle_inhibitor"
            "power-profiles-daemon"
          ];
        };

        battery = {
          format = "{icon} {capacity}%";
          format-discharging = "{icon}";
          format-charging = "{icon}";
          format-plugged = "";
          format-icons = {
            charging = [
              "󰢜"
              "󰂆"
              "󰂇"
              "󰂈"
              "󰢝"
              "󰂉"
              "󰢞"
              "󰂊"
              "󰂋"
              "󰂅"
            ];
            default = [
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
          };
          format-full = "󰂅";
          tooltip-format-discharging = "{power:>1.2f}W↓ {capacity}%\n{timeTo}";
          tooltip-format-charging = "{power:>1.2f}W↑ {capacity}%\n{timeTo}";
          tooltip-format-plugged = "{capacity}%";
          interval = 5;
          states = {
            warning = 20;
            critical = 10;
          };
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
        };

        power-profiles-daemon = {
          format = "{icon}";
          tooltip-format = "Power profile: {profile}\nDriver: {driver}";
          tooltip = true;
          format-icons = {
            default = "";
            performance = "";
            balanced = "";
            power-saver = "";
          };
        };

        "group/hardware" = {
          orientation = "inherit";

          drawer = {
            transition-duration = 300;
            transition-left-to-right = false;
          };

          modules = [
            "custom/monitor"
            "disk"
            "cpu"
            "temperature"
            "memory"
          ];
        };

        "custom/monitor" = {
          format = "";
          tooltip = false;
          on-click = "hyprctl dispatch togglespecialworkspace monitor";
        };

        disk = {
          format = "󰋊 {percentage_free}%";
        };

        cpu = {
          format = " {usage}%";
          interval = 5;
        };

        temperature = {
          format = " {temperatureC}°C";
          interval = 5;
          critical-format = "󰸁 {temperatureC}°C";
          critical-threshold = 90;
        };

        memory = {
          format = " {used}/{total}GiB";
          interval = 5;
        };

        tray = {
          spacing = 5;
        };
      };
    };

    style = ''
      * {
        padding: 0;
        margin: 0;
        font-family: "Ubuntu Nerd Font", "Ubuntu", sans-serif;
      }

      window#waybar {
        transition: all 0.3s ease-in-out;
      }

      .module {
        color: @base05;
        background: @base01;
        border-radius: ${borderRadius}px;

        padding: 0.2rem 0.5rem;
        margin: 0.4rem 0.2rem;
      }

      .modules-left:first-child {
        margin-left: 0.2em;
      }

      .modules-right:last-child {
        margin-right: 0.2em;
      }

      tooltip {
        background: @base00;
        border: ${borderSize}px solid @base0D;
        border-radius: ${borderRadius}px;
      }

      tooltip label {
        color: @base05;

        padding: 0.2rem 0.5rem;
      }

      window#waybar.battery-critical {
        background: mix(@base00, @base08, 0.3);
      }

      #custom-actions {
        color: @base0B;
        font-size: 1.3em;
      }

      #workspaces button {
        color: @base05;

        padding: 0.05rem;
        margin: 0.2rem 0.3rem;
        transition: all 0.3s ease-in-out;
      }

      #workspace button:first-child {
        margin: 0.2rem 0.3rem 0.2rem 0px;
      }

      #workspace button:last-child {
        margin: 0.2rem 0px 0.2rem 0.3rem;
      }

      #workspaces button.empty {
        color: @base03;
      }

      #workspaces button.visible {
        color: @base0E;
      }

      #workspaces button.active {
        color: @base0D;
      }

      #workspaces button.special {
        color: @base0C;
      }

      #workspaces button:hover {
        color: @base0B;
        background: transparent;
      }

      window#waybar.empty #window {
        background: transparent;
      }

      #privacy {
        color: @base00;
        background: @base0A;
        border-radius: ${borderRadius}px;

        padding: 0.2rem 0.5rem;
        margin: 0.4rem 0.2rem;
      }

      #wireplumber.muted {
        color: @base00;
        background: @base0A;
      }

      #battery.warning {
        color: @base00;
        background: @base0A;
      }

      #battery.charging,
      #battery.plugged {
        color: @base00;
        background: @base0B;
      }

      @keyframes blink {
        to {
          color: @base05;
          background: @base01;
        }
      }

      #battery.critical:not(.charging) {
        background-color: @base08;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      #power-profiles-daemon {
        color: @base00;
      }

      #power-profiles-daemon.performance {
        background: @base08;
      }

      #power-profiles-daemon.balanced {
        background: @base0B;
      }

      #power-profiles-daemon.power-saver {
        background: @base0D;
      }

      #idle_inhibitor {
        background: @base02;
      }

      #idle_inhibitor.activated {
        color: @base00;
        background: @base09;
      }

      #disk,
      #cpu,
      #temperature,
      #memory {
        background: @base02;
      }

      #temperature.critical {
        color: @base08;
      }

      #tray {
        background: @base02;
      }

      #tray menu,
      #tray menuitem {
        padding: 0.25rem;
        margin: 0.1rem;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: @base0A;
      }
    '';
  };

  xdg.configFile."waybar/style.css" = {
    onChange = ''
      ${pkgs.procps}/bin/pkill -u $USER waybar || true
    '';
  };
}
