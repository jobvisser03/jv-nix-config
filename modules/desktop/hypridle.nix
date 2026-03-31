# Hypridle idle management configuration
# Home-manager only module (NixOS-only, not macOS)
{...}: {
  flake.modules.homeManager.hypridle = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.hypridle.suspendOnIdle = lib.mkEnableOption "Suspend system after idle timeout" // {default = true;};

    config = {
      services.hypridle = {
        enable = true;

        settings = {
          general = {
            lock_cmd = "pgrep hyprlock || hyprlock";
            unlock_cmd = "pkill -SIGUSR1 hyprlock";
          };

          listener =
            [
              # Save and restore brightness across idle
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
              # Dim screen
              {
                timeout = 120;
                on-timeout = "brightnessctl set 50%-";
              }
              # Lock screen
              {
                timeout = 300;
                on-timeout = "pgrep hyprlock || hyprlock --grace 3";
              }
              # Turn off display
              {
                timeout = 360;
                on-timeout = "hyprctl dispatch dpms off";
                on-resume = "hyprctl dispatch dpms on";
              }
            ]
            # Suspend - only if suspendOnIdle is enabled
            ++ lib.optionals config.hypridle.suspendOnIdle [
              {
                timeout = 480;
                on-timeout = "systemctl suspend";
              }
            ];
        };
      };
    };
  };
}
