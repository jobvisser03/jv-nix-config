{ pkgs, lib, config, ... }:
  # NixOS-specific Home Manager options go here
  # Example: Hyprland, Wayland, Linux-only packages, etc.


  #      ${pkgs.swww}/bin/swww img ${./wallpaper.png} &
 let
    startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
      ${pkgs.waybar}/bin/waybar &
      ${pkgs.swww}/bin/swww init &

      sleep 1

    '';
in
{
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
          "$mod SHIFT, Q, exit"  # Logout keybind
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (builtins.genList (i:
              let ws = i + 1;
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

  home.packages = with pkgs; [
    # Add NixOS-specific packages here
    # e.g. pkgs.waybar, pkgs.swww
    keepassxc
    drawio
    anki-bin
    docker-client
  ];
  # Add more NixOS-specific config as needed
}
