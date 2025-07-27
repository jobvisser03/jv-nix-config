{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
# NixOS-specific Home Manager options go here
# Example: Hyprland, Wayland, Linux-only packages, etc.
let
  startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
    ${pkgs.waybar}/bin/waybar &
    ${pkgs.hypridle}/bin/hypridle
  '';
  inherit (lib) mkForce;
  inherit (config.lib.formats.rasi) mkLiteral;
in {
  imports = [
    ../modules/wm/waybar.nix
    ../modules/wm/hyprlock.nix
    ../modules/wm/hypridle.nix
    ../modules/home-manager/rofi.nix
  ];
  home.packages = with pkgs; [
    keepassxc
    drawio
    anki-bin
    docker-client
    overskride
    nautilus
  ];

  stylix.enable = true;
  stylix.polarity = "dark";

  wayland.windowManager.hyprland = {
    enable = true;
    # set the Hyprland and XDPH packages to null to use the ones from the NixOS module
    package = null;
    portalPackage = null;
    #  plugins = [
    #    inputs.hyprland-plugins.packages."${pkgs.system}".borders-plus-plus
    #  ];

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

      # GESTURES
      gestures = {
        workspace_swipe = true;
      };

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
    #  "plugin:borders-plus-plus" = {
    #    add_borders = 1; # 0 - 9

    #    # you can add up to 9 borders
    #    "col.border_1" = "rgb(ffffff)";
    #    "col.border_2" = "rgb(2222ff)";

    #    # -1 means "default" as in the one defined in general:border_size
    #    border_size_1 = 10;
    #    border_size_2 = -1;

    #    # makes outer edges match rounding of the parent. Turn on / off to better understand. Default = on.
    #    natural_rounding = "yes";
    #  };
  };
  # Add more NixOS-specific config as needed
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };

  # TODO add rofi config from seperate file
  # programs.rofi = {
  #   enable = true;
  #   cycle = false;

  #   package = pkgs.rofi-wayland;
  #   extraConfig = {
  #     modi = "drun,filebrowser";
  #     font = "Noto Sans CJK JP 12";
  #     show-icons = true;
  #     disable-history = true;
  #     hover-select = true;
  #     bw = 0;
  #     display-drun = "";
  #     display-window = "";
  #     display-combi = "";
  #     icon-theme = "Fluent-dark";
  #     terminal = "wezterm";
  #     drun-match-fields = "name";
  #     drun-display-format = "{name}";
  #     me-select-entry = "";
  #     me-accept-entry = "MousePrimary";
  #     kb-cancel = "Escape,MouseMiddle";
  #   };

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
  # };
}
