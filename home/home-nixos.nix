{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
    ${pkgs.waybar}/bin/waybar &
    ${pkgs.hypridle}/bin/hypridle
  '';
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
    package = null;
    portalPackage = null;

    settings = {
      exec-once = ''${startupScript}/bin/start'';

      "$mod" = "SUPER";

      input = {
        kb_options = "caps:swapescape";
      };

      env = [
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "ELECTRON_ENABLE_WAYLAND,1"
      ];

      ecosystem = {
        no_donation_nag = true;
      };

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
      };

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

      bind =
        [
          "$mod, F, exec, firefox"
          "$mod, T, exec, kitty"
          "$mod, D, exec, rofi -show drun"
          ", Print, exec, grimblast copy area"
          "$mod SHIFT, Q, exit"
        ]
        ++ (
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
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };
}
