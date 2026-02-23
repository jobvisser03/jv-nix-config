{...}: {
  services.hypridle = {
    enable = true;
    settings = {
      # Lock when suspend
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "pidof hyprlock || hyprlock";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        # Lock screen after n seconds
        {
          timeout = 1200;
          on-timeout = "pidof hyprlock || hyprlock";
        }
      ];
    };
  };
}
