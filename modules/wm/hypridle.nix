{...}: {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        unlock_cmd = "pkill -SIGUSR1 hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 10;
          on-timeout = "brightnessctl --save";
          on-resume = "brightnessctl --restore";
        }
        {
          timeout = 30;
          on-timeout = "brightnessctl --device *:kbd_backlight --save set 0";
          on-resume = "brightnessctl --device *:kbd_backlight --restore";
        }
        {
          timeout = 50;
          on-timeout = "brightnessctl set 50%-";
        }
        {
          timeout = 110;
          on-timeout = "brightnessctl set 50%-";
        }
        {
          timeout = 120;
          on-timeout = "pidof hyprlock || hyprlock --grace 3";
        }
        {
          timeout = 140;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 600;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
