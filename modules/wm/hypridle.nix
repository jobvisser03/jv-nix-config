{lib, config, ...}:
{
  services.hypridle = {
    enable = true;

    settings = let
      isLocked = command: "pgrep hyprlock && ${command}";
    in {
      general = {
        lock_cmd = "pgrep hyprlock || hyprlock";
        unlock_cmd = "pkill -SIGUSR1 hyprlock";
        # NOTE: Removed before_sleep_cmd and after_sleep_cmd - no sleep/suspend behavior
      };

      listener = [
        # Save brightness state early
        {
          timeout = 10;
          on-timeout = "brightnessctl --save";
          on-resume = "brightnessctl --restore";
        }
        # Turn off keyboard backlight
        {
          timeout = 30;
          on-timeout = "brightnessctl --device *:kbd_backlight --save set 0";
          on-resume = "brightnessctl --device *:kbd_backlight --restore";
        }
        # Dim screen progressively
        {
          timeout = 50;
          on-timeout = "brightnessctl set 50%-";
        }
        {
          timeout = 110;
          on-timeout = "brightnessctl set 50%-";
        }
        # Lock screen
        {
          timeout = 120;
          on-timeout = "pgrep hyprlock || hyprlock --grace 3";
        }
        # Turn off display
        {
          timeout = 140;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }

        # If already locked - dim faster and turn off display sooner
        {
          timeout = 15;
          on-timeout = isLocked "brightnessctl set 75%-";
        }
        {
          timeout = 20;
          on-timeout = isLocked "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }

        # NOTE: Removed suspend/sleep/logout listeners - only lock screen behavior
      ];
    };
  };
}
