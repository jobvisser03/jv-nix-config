# Dunst notification daemon configuration
# Home-manager module
{...}: {
  flake.modules.homeManager.dunst = {
    config,
    ...
  }: let
    stylix = config.lib.stylix.colors.withHashtag;
  in {
    services.dunst = {
      enable = true;
      settings = {
        global = {
          width = 400;
          height = 300;
          offset = "10x10";
          origin = "top-right";
          transparency = 10;
          frame_color = stylix.base0D;
          frame_width = 2;
          corner_radius = 10;
          font = "Ubuntu Nerd Font 12";
          markup = "full";
          format = "<b>%a</b>\\n%s\\n%b";
          alignment = "left";
          vertical_alignment = "center";
          show_age_threshold = 60;
          ellipsize = "end";
          padding = 12;
          horizontal_padding = 12;
          text_icon_padding = 12;
          icon_position = "left";
          max_icon_size = 64;
          progress_bar = true;
          progress_bar_height = 10;
          progress_bar_frame_width = 1;
          progress_bar_min_width = 150;
          progress_bar_max_width = 400;
          progress_bar_corner_radius = 5;
          mouse_left_click = "do_action, close_current";
          mouse_middle_click = "close_all";
          mouse_right_click = "close_current";
        };

        urgency_low = {
          background = stylix.base01;
          foreground = stylix.base05;
          frame_color = stylix.base03;
          timeout = 5;
        };

        urgency_normal = {
          background = stylix.base01;
          foreground = stylix.base05;
          frame_color = stylix.base0D;
          timeout = 8;
        };

        urgency_critical = {
          background = stylix.base01;
          foreground = stylix.base05;
          frame_color = stylix.base08;
          timeout = 0;
        };
      };
    };
  };
}
