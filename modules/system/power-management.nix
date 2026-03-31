# Power management configuration
# NixOS only - provides desktopMode option for always-on systems
{...}: {
  flake.modules.nixos.power-management = {
    lib,
    config,
    ...
  }: {
    options.powerManagement.desktopMode = lib.mkEnableOption "Desktop mode (no battery, always plugged in)";

    config = lib.mkMerge [
      # Common settings for all systems
      {
        # Enable suspend and set lid close to suspend
        services.logind.settings.Login = {
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "suspend";
        };
      }

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
            # CPU governor
            CPU_SCALING_GOVERNOR_ON_AC = "performance";
            CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

            # CPU boost
            CPU_BOOST_ON_AC = 1;
            CPU_BOOST_ON_BAT = 0;
            CPU_HWP_DYN_BOOST_ON_AC = 1;
            CPU_HWP_DYN_BOOST_ON_BAT = 0;

            # CPU energy/performance policy
            CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
            CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

            # CPU performance scaling
            CPU_MIN_PERF_ON_AC = 0;
            CPU_MAX_PERF_ON_AC = 100;
            CPU_MIN_PERF_ON_BAT = 0;
            CPU_MAX_PERF_ON_BAT = 40;

            # Platform profile (if supported by firmware)
            PLATFORM_PROFILE_ON_AC = "performance";
            PLATFORM_PROFILE_ON_BAT = "low-power";

            # WiFi power saving
            WIFI_PWR_ON_AC = "off";
            WIFI_PWR_ON_BAT = "on";

            # PCI runtime power management - lets idle devices enter low-power states
            RUNTIME_PM_ON_AC = "auto";
            RUNTIME_PM_ON_BAT = "auto";

            # AMD Radeon dGPU power management
            RADEON_DPM_STATE_ON_AC = "performance";
            RADEON_DPM_STATE_ON_BAT = "battery";
            RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
            RADEON_DPM_PERF_LEVEL_ON_BAT = "low";
            AMDGPU_ABM_LEVEL_ON_AC = 0;
            AMDGPU_ABM_LEVEL_ON_BAT = 3;

            # Audio codec power save - turns off codec after 1s of silence
            SOUND_POWER_SAVE_ON_AC = 0;
            SOUND_POWER_SAVE_ON_BAT = 1;

            # Disable NMI watchdog - saves ~1W
            NMI_WATCHDOG = 0;

            # Restore device state on startup
            RESTORE_DEVICE_STATE_ON_STARTUP = 1;

            # Battery charge thresholds for long-term health
            START_CHARGE_THRESH_BAT0 = 40; # 40 and below it starts to charge
            STOP_CHARGE_THRESH_BAT0 = 80; # 80 and above it stops charging
          };
        };
      })
    ];
  };
}
