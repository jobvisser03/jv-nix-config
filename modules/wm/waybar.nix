{config, lib, ...}: let
  stylix = config.lib.stylix.colors.withHashtag;
in
{  programs.waybar = {
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
          "clock"
          "mpris"
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
          format = "";
          tooltip-format = "System Actions";
          on-click = "wofi --show drun";
        };

        "hyprland/workspaces" = {
          show-special = true;
          special-visible-only = true;
          format = "{icon}";

          format-icons = {
            "discord" = "";
            "todo" = "";
            "monitor" = "󰍹";
            "obsidian" = "";
            "spotify" = "";
            "default" = "";
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

        clock = {
          format = " {:%A %H:%M}";

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

        mpris = {
          player = "spotify";
          format = "{player_icon} {status_icon} <b>{title}</b> by <i>{artist}</i>";
          tooltip-format = "Album: {album}";
          artist-len = 12;
          title-len = 22;
          ellipsis = "...";
          player-icons = {
            default = "";
            spotify = "󰓇";
          };
          status-icons = {
            paused = "󰏤";
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
          on-click = "pwvucontrol";
          on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
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
          ];
        };

        battery = {
          format = "{icon} {capacity}%";
          format-discharging = "{icon}";
          format-charging = "{icon}";
          format-plugged = "";
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
            activated = "";
            deactivated = "";
          };
        };

        "group/hardware" = {
          orientation = "inherit";

          drawer = {
            transition-duration = 300;
            transition-left-to-right = false;
          };

          modules = [
            "disk"
            "cpu"
            "temperature"
            "memory"
          ];
        };

        disk = {
          format = "󰋊 {percentage_free}%";
        };

        cpu = {
          format = " {usage}%";
          interval = 5;
        };

        temperature = {
          format = " {temperatureC}°C";
          interval = 5;
          critical-format = "󰸁 {temperatureC}°C";
          critical-threshold = 90;
        };

        memory = {
          format = " {used}/{total}GiB";
          interval = 5;
        };

        tray = {
          spacing = 5;
        };
      };
    };
  };
}
