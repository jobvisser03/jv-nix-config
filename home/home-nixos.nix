{
  pkgs,
  lib,
  config,
  ...
}:
# NixOS-specific Home Manager options go here
# Example: Hyprland, Wayland, Linux-only packages, etc.
let

  startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
    ${pkgs.waybar}/bin/waybar &
    ${pkgs.swww}/bin/swww init &

    sleep 0.1

    ${pkgs.swww}/bin/swww img /home/job/Pictures/nixos-wallpaper-catppuccin-frappe.png &
  '';
  inherit (lib) mkForce;
  inherit (config.lib.formats.rasi) mkLiteral;
  rofi-theme = {
    "*" = {
      background-color = mkLiteral "#00ff00";
    };
  };
in {

  imports = [
    # ../hosts/mac-intel-nixos-host/modules/wm/waybar.nix
  ];

  home.packages = with pkgs; [
    keepassxc
    drawio
    anki-bin
    docker-client
    overskride
  ];

  programs.stylix.enable = false;
  programs.stylix.autoEnable = false;

  wayland.windowManager.hyprland = {
    enable = true;
    # set the Hyprland and XDPH packages to null to use the ones from the NixOS module
    package = null;
    portalPackage = null;
    #    plugins = [
    #      inputs.hyprland-plugins.packages."${pkgs.system}".borders-plus-plus
    #    ];

    settings = {
      exec-once = ''${startupScript}/bin/start'';

      "$mod" = "SUPER";

      input = {
        kb_options = "caps:swapescape";
      };

      # Environment variables for better Electron app support
      env = [
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "ELECTRON_ENABLE_WAYLAND,1"
      ];

      bind =
        [
          "$mod, F, exec, firefox"
          "$mod, T, exec, kitty"
          "$mod, D, exec, rofi -show drun"
          ", Print, exec, grimblast copy area"
          "$mod SHIFT, Q, exit" # Logout keybind
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (builtins.genList (
              i: let
                ws = i + 1;
              in [
                "$mod, code:1${toString i}, workspace, ${toString ws}"
                "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            )
            9)
        );
    };
    #      "plugin:borders-plus-plus" = {
    #        add_borders = 1; # 0 - 9
    #
    #        # you can add up to 9 borders
    #        "col.border_1" = "rgb(ffffff)";
    #        "col.border_2" = "rgb(2222ff)";
    #
    #        # -1 means "default" as in the one defined in general:border_size
    #        border_size_1 = 10;
    #        border_size_2 = -1;
    #
    #        # makes outer edges match rounding of the parent. Turn on / off to better understand. Default = on.
    #        natural_rounding = "yes";
    #      };
  };
  # Add more NixOS-specific config as needed
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };

  programs.waybar = {
    enable = true;
    package = pkgs.waybar;

    settings = {
      top_bar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 4;
        modules-left = [
          "custom/os_button"
          "hyprland/workspaces"
        ];
        modules-center = [
          "clock#time"
          "custom/separator"
          "clock#calendar"
        ];
        modules-right = [
          "tray"
          "temperature"
          "cpu"
          "memory"
          "disk"
          "battery"
          "pulseaudio"
        ];

        "custom/os_button" = {
          format = "󱄅";
          tooltip = false;
        };

        "hyprland/workspaces" = {
          on-click = "activate";
          format = "{icon}";
          format-icons = {
            active = "";
            default = "";
            empty = "";
          };
          persistent-workspaces = {
            "*" = 10;
          };
        };

        "custom/separator" = {
          format = "|";
          tooltip = false;
        };

        "clock#calendar" = {
          format = "{:%F}";
          "tooltip-format" = "<tt><small>{calendar}</small></tt>";
          mode = "year";
          actions = {
            on-click-right = "mode";
          };
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll-right = "mode";
            format = {
              months = "<span color='#edb53d'><b>{}</b></span>";
              days = "<span color='#edb53d'><b>{}</b></span>";
              weeks = "<span color='#edb53d'><b>W{}</b></span>";
              weekdays = "<span color='#edb53d'><b>{}</b></span>";
              today = "<span color='#fe8019'><b><u>{}</u></b></span>";
            };
          };
        };

        "clock#time" = {
          format = "{:%H:%M}";
          "tooltip-format" = "<tt><small>{calendar}</small></tt>";
          actions = {
            on-click-right = "mode";
          };
          calendar = {
            mode = "month";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            on-click-right = "mode";
            format = {
              months = "<span color='#edb53d'><b>{}</b></span>";
              days = "<span color='#edb53d'><b>{}</b></span>";
              weeks = "<span color='#edb53d'><b>W{}</b></span>";
              weekdays = "<span color='#edb53d'><b>{}</b></span>";
              today = "<span color='#fe8019'><b><u>{}</u></b></span>";
            };
          };
        };

        cpu = {
          format = "󰻠 {usage}%";
          states = {
            high = 90;
            upper-medium = 70;
            medium = 50;
            lower-medium = 30;
            low = 10;
          };
          on-click = "kitty btop";
        };

        temperature = {
          interval = 10;
          tooltip = false;
          thermal-zone = 0;
          critical-threshold = 80;
          format = " {temperatureC}°C";
        };

        memory = {
          format = "  {percentage}%";
          tooltip-format = "Main: ({used} GiB/{total} GiB)({percentage}%), available {avail} GiB";
          states = {
            high = 90;
            upper-medium = 70;
            medium = 50;
            lower-medium = 30;
            low = 10;
          };
          on-click = "kitty btop";
        };

        disk = {
          format = "󰋊 {percentage_used}%";
          tooltip-format = "({used}/{total})({percentage_used}%) in '{path}', available {free}({percentage_free}%)";
          states = {
            high = 90;
            upper-medium = 70;
            medium = 50;
            lower-medium = 30;
            low = 10;
          };
          on-click = "kitty btop";
        };

        battery = {
          states = {
            high = 90;
            upper-medium = 70;
            medium = 50;
            lower-medium = 30;
            low = 10;
          };
          format = "{icon}{capacity}%";
          format-charging = "󱐋{icon}{capacity}%";
          format-plugged = "󰚥{icon}{capacity}%";
          format-time = "{H} h {M} min";
          format-icons = [
            "󱃍 "
            "󰁺 "
            "󰁻 "
            "󰁼 "
            "󰁽 "
            "󰁾 "
            "󰁿 "
            "󰂀 "
            "󰂁 "
            "󰂂 "
            "󰁹 "
          ];
          tooltip-format = "{timeTo}";
        };

        tray = {
          icon-size = 20;
          spacing = 2;
        };

        "pulseaudio" = {
          tooltip-format = "{desc}\n{format_source}";
          format = "{icon} {format_source}";
          format-muted = "󰝟 {format_source}";
          format-source = "󰍬";
          format-source-muted = "󰍭";
          format-icons = {
            headphone = "󰋋 ";
            hands-free = " ";
            headset = "󰋎 ";
            phone = "󰄜 ";
            portable = "󰦧 ";
            car = "󰄋 ";
            hdmi = "󰡁 ";
            hifi = "󰋌 ";
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          on-click = "pwvucontrol";
        };
      };
    };
  };

  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
        grace = 2;
      };

      background = mkForce {
        color = "rgba(25, 20, 20, 1.0)";
        path = "screenshot";
        blur_passes = 2;
        brightness = 0.5;
      };

      label = {
        text = "Yes Yes Yes";
        color = "rgba(222, 222, 222, 1.0)";
        font_size = 50;
        font_family = "Noto Sans CJK JP";
        position = "0, 70";
        halign = "center";
        valign = "center";
      };

      input-field = {
        size = "50, 50";
        dots_size = 0.33;
        dots_spacing = 0.15;
        outer_color = mkForce "rgba(25, 20, 20, 0)";
        inner_color = mkForce "rgba(25, 20, 20, 0)";
        font_color = mkForce "rgba(222, 222, 222, 1.0)";
        placeholder_text = "パスワード";
      };
    };
  };

  programs.rofi = {
    enable = true;
    cycle = false;

    package = pkgs.rofi-wayland;
    theme = rofi-theme;
    extraConfig = {
      modi = "drun,filebrowser";
      font = "Noto Sans CJK JP 12";
      show-icons = true;
      disable-history = true;
      hover-select = true;
      bw = 0;
      display-drun = "";
      display-window = "";
      display-combi = "";
      icon-theme = "Fluent-dark";
      terminal = "wezterm";
      drun-match-fields = "name";
      drun-display-format = "{name}";
      me-select-entry = "";
      me-accept-entry = "MousePrimary";
      kb-cancel = "Escape,MouseMiddle";
    };

    # # Based on Newman Sánchez's Launchpad theme <https://github.com/newmanls/rofi-themes-collection>
    # theme = mkForce {
    #   "*" = {
    #     font = "Noto Sans CJK JP Bold 12";
    #     background-color = mkLiteral "transparent";
    #     foreground = mkLiteral "${base05}";
    #     text-color = mkLiteral "${base05}";
    #     padding = mkLiteral "0px";
    #     margin = mkLiteral "0px";
    #   };

    #   window = {
    #     fullscreen = true;
    #     padding = mkLiteral "1em";
    #     background-color = mkLiteral "${base00}dd";
    #   };

    #   mainbox = {
    #     padding = mkLiteral "8px";
    #   };

    #   inputbar = {
    #     background-color = mkLiteral "${base05}20";

    #     margin = mkLiteral "0px calc( 50% - 230px )";
    #     padding = mkLiteral "4px 8px";
    #     spacing = mkLiteral "8px";

    #     border = mkLiteral "1px";
    #     border-radius = mkLiteral "2px";
    #     border-color = mkLiteral "${base05}40";

    #     children = map mkLiteral [
    #       "icon-search"
    #       "entry"
    #     ];
    #   };

    # prompt = {
    #   enabled = false;
    # };

    # icon-search = {
    #   expand = false;
    #   filename = "search";
    #   # vertical-align = mkLiteral "0.5";
    # };

    # entry = {
    #   placeholder = "Search";
    #   # placeholder-color = mkLiteral "${base05}20";
    # };

    # listview = {
    #   margin = mkLiteral "48px calc( 50% - 720px )";
    #   margin-bottom = mkLiteral "0px";
    #   spacing = mkLiteral "48px";
    #   columns = 6;
    #   fixed-columns = true;
    # };

    # "element, element-text, element-icon" = {
    #   cursor = mkLiteral "pointer";
    # };

    # element = {
    #   padding = mkLiteral "8px";
    #   spacing = mkLiteral "4px";

    #   orientation = mkLiteral "vertical";
    #   border-radius = mkLiteral "12px";
    # };

    # "element selected" = {
    #   background-color = mkLiteral "${base05}33";
    # };

    # element-icon = {
    #   size = mkLiteral "5.75em";
    #   horizontal-align = mkLiteral "0.5";
    # };

    # element-text = {
    #   horizontal-align = mkLiteral "0.5";
    # };
    # };
  };
}
