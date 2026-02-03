{
  lib,
  config,
  ...
}: {
  options.powerManagement.desktopMode = lib.mkEnableOption "Desktop mode (no battery, always plugged in)";

  config = lib.mkMerge [
    # Desktop mode - simple performance-focused settings
    (lib.mkIf config.powerManagement.desktopMode {
      # Disable TLP (it's for laptops with batteries)
      services.tlp.enable = false;
      services.power-profiles-daemon.enable = false;

      # Use performance governor for always-on desktop
      powerManagement.cpuFreqGovernor = "performance";
    })

    # Laptop mode - keep TLP with battery optimizations
    (lib.mkIf (!config.powerManagement.desktopMode) {
      services.power-profiles-daemon.enable = false;

      services.tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 0;

          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

          CPU_MIN_PERF_ON_AC = 0;
          CPU_MAX_PERF_ON_AC = 100;
          CPU_MIN_PERF_ON_BAT = 0;
          CPU_MAX_PERF_ON_BAT = 20;

          RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
          RADEON_DPM_PERF_LEVEL_ON_BAT = "low";

          # Optional helps save long term battery health
          START_CHARGE_THRESH_BAT0 = 40; # 40 and below it starts to charge
          STOP_CHARGE_THRESH_BAT0 = 80; # 80 and above it stops charging
        };
      };
    })
  ];
}
