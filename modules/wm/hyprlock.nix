{...}: {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        grace = 3;
        hide_cursor = false;
      };

      background = {
        blur_size = 4;
        blur_passes = 2;
        brightness = 0.6;
      };

      input-field = {
        size = "250, 50";
        outline_thickness = 2;
        dots_size = 0.2;
        dots_spacing = 0.15;
        dots_center = true;
        fade_on_empty = false;
        fade_timeout = 1000;
        placeholder_text = "Password";
        hide_input = false;
        rounding = 7;
        position = "0, -50";
        halign = "center";
        valign = "center";
      };

      image = {
        path = "~/.face";
        size = 100;
        border_color = "rgb(80, 250, 123)";
        position = "0, 60";
        halign = "center";
        valign = "center";
      };

      label = [
        {
          text = "$TIME";
          color = "rgb(80, 250, 123)";
          font_size = 72;
          font_family = "Ubuntu Nerd Font";
          position = "0, 0";
          halign = "center";
          valign = "center";
        }
        {
          text = "cmd[update:3600000] echo \"$(date +'%A, %d %B %Y')\"";
          color = "rgb(80, 250, 123)";
          font_size = 20;
          font_family = "Ubuntu Nerd Font";
          position = "0, -120";
          halign = "center";
          valign = "center";
        }
        {
          text = "Suspend";
          color = "rgb(80, 250, 123)";
          font_size = 14;
          position = "0, 10";
          halign = "center";
          valign = "bottom";
        }
      ];

      shape = [
        {
          color = "rgb(40, 42, 54)";
          onclick = "systemctl suspend";
          size = "100, 30";
          rounding = 7;
          position = "0, 4";
          halign = "center";
          valign = "bottom";
        }
      ];
    };
  };
}
