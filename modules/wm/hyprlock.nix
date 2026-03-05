{config, lib, ...}: let
  stylix = config.lib.stylix.colors;
  rgb = color: "rgb(${color})";
in
{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        grace = 3;
        hide_cursor = false;
      };

      auth.fingerprint.enabled = true;

      background = {
        blur_size = 4;
        blur_passes = 2;
        brightness = 0.75;
      };

      input-field = {
        size = "300, 50";
        outline_thickness = 3;
        dots_size = 0.25;
        dots_spacing = 0.15;
        dots_center = true;
        dots_rounding = -1;
        fade_on_empty = false;
        fade_timeout = 1000;
        placeholder_text = "<span foreground=\"##${stylix.base05}\">󰌾  Logged in as <span foreground=\"##${stylix.base0D}\"><i>$USER</i></span></span>";
        hide_input = false;
        rounding = -1;
        fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
        capslock_color = rgb stylix.base0A;

        position = "0, -70";
        halign = "center";
        valign = "center";
      };

      image = {
        path = "~/.face";
        size = 150;
        border_color = rgb stylix.base0D;

        position = "0, 75";
        halign = "center";
        valign = "center";
      };

      label = [
        {
          text = "$TIME";
          color = rgb stylix.base05;
          font_size = 90;
          font_family = config.stylix.fonts.sansSerif.name;
          position = "-30, 0";
          halign = "right";
          valign = "top";
        }
        {
          text = "cmd[update:43200000] echo \"$(date +\"%A, %d %B %Y\")\"";
          color = rgb stylix.base05;
          font_size = 25;
          font_family = config.stylix.fonts.sansSerif.name;
          position = "-30, -150";
          halign = "right";
          valign = "top";
        }
        {
          text = "cmd[update:1000] ~/.config/hypr/scripts/get_battery_info.sh";
          color = rgb stylix.base05;
          font_size = 18;
          font_family = config.stylix.fonts.sansSerif.name;
          position = "-30, -210";
          halign = "right";
          valign = "top";
        }
      ];

      # NOTE: No suspend button - lock screen only, no sleep/suspend actions
    };
  };
}
