# Power management configuration
# NixOS only - laptops run power-profiles-daemon (switched from Noctalia on
# Niri); desktopMode is for always-on systems without a battery.
{...}: {
  flake.modules.nixos.power-management = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.powerManagement;
    laptop = !cfg.desktopMode;

    # Battery -> power-saver, AC -> balanced. Noctalia can still switch
    # profiles by hand until the next plug event.
    ppdAcSwitch = pkgs.writeShellScript "ppd-ac-switch" ''
      profile=power-saver
      for supply in /sys/class/power_supply/*; do
        if [ "$(cat "$supply/type")" = Mains ] && [ "$(cat "$supply/online")" = 1 ]; then
          profile=balanced
        fi
      done
      exec ${lib.getExe' config.services.power-profiles-daemon.package "powerprofilesctl"} set "$profile"
    '';
  in {
    options.powerManagement = {
      desktopMode = lib.mkEnableOption "Desktop mode (no battery, always plugged in)";

      chargeStopThreshold = lib.mkOption {
        type = lib.types.ints.between 50 100;
        default = 80;
        description = "Stop charging the battery at this percentage, for long-term health.";
      };
    };

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
      (lib.mkIf cfg.desktopMode {
        services.power-profiles-daemon.enable = false;

        # Use performance governor for always-on desktop
        powerManagement.cpuFreqGovernor = "performance";
      })

      # Laptop - ppd only sets CPU EPP and the platform profile, so the rest
      # of the battery tuning is done here.
      (lib.mkIf laptop {
        services.upower.enable = true;
        services.power-profiles-daemon.enable = true;

        # Disable NMI watchdog - saves ~1W
        boot.kernel.sysctl."kernel.nmi_watchdog" = 0;

        # Deepest PCIe link power states. Revert if Wi-Fi or NVMe misbehave.
        boot.kernelParams = ["pcie_aspm.policy=powersupersave"];

        networking.networkmanager.wifi.powersave = true;

        # PCI runtime power management - lets idle devices enter low-power states
        services.udev.extraRules = ''
          ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
          SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl start --no-block ppd-ac-switch.service"
        '';

        systemd.services.ppd-ac-switch = {
          description = "Pick power profile for AC or battery";
          after = ["power-profiles-daemon.service"];
          requires = ["power-profiles-daemon.service"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = ppdAcSwitch;
          };
        };

        # The charge-control attribute can appear after the battery's udev add
        # event (EC driver hook), so set it from a boot service instead.
        systemd.services.battery-charge-threshold = {
          description = "Set battery charge stop threshold";
          wantedBy = ["multi-user.target"];
          serviceConfig.Type = "oneshot";
          script = ''
            for attr in /sys/class/power_supply/*/charge_control_end_threshold; do
              [ -w "$attr" ] && echo ${toString cfg.chargeStopThreshold} > "$attr"
            done
            true
          '';
        };
      })
    ];
  };
}
