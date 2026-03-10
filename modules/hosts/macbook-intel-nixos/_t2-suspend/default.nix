# T2 Mac suspend/resume fix module
# Based on: https://github.com/t2linux/T2-Debian-and-Ubuntu-Kernel/issues/53
# and https://github.com/deqrocks/T2Linux-Suspend-Fix
#
# This module provides systemd services to handle suspend/resume on T2 Macs.
# When used with klizas's patched apple-bce driver, no module unloading is needed.
# The driver handles suspend/resume internally, we just need to:
# - Handle WiFi/Bluetooth around suspend
# - Rebind Touch Bar HID driver on resume
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hardware.apple-t2-suspend;

  # Suspend/resume script for T2 Macs
  suspendScript = pkgs.writeShellScript "suspend-fix-t2.sh" ''
    # Suspend workaround for T2 Macs with Touch Bar
    # Works with klizas's patched apple-bce driver that handles suspend/resume internally

    case "$1" in
        pre)
            # Disable async PM operations for more reliable suspend
            echo 0 > /sys/power/pm_async

            # Stop NetworkManager to prevent issues during suspend
            ${pkgs.systemd}/bin/systemctl stop NetworkManager

            # Block WiFi and Bluetooth
            ${pkgs.util-linux}/bin/rfkill block wifi
            ${pkgs.util-linux}/bin/rfkill block bluetooth
            ;;
        post)
            # Re-enable async PM operations
            echo 1 > /sys/power/pm_async

            # Unblock WiFi and Bluetooth
            ${pkgs.util-linux}/bin/rfkill unblock wifi
            ${pkgs.util-linux}/bin/rfkill unblock bluetooth

            # Restart NetworkManager
            ${pkgs.systemd}/bin/systemctl start NetworkManager

            # Rebind Touch Bar HID driver (safer than USB re-auth)
            # This is still needed even with patched apple-bce driver
            sleep 1
            for dev in /sys/bus/hid/drivers/hid-appletb-kbd/0003:*; do
                if [[ -L "$dev" ]]; then
                    devid=$(${pkgs.coreutils}/bin/basename "$dev")
                    echo "$devid" > /sys/bus/hid/drivers/hid-appletb-kbd/unbind 2>/dev/null || true
                    sleep 0.3
                    echo "$devid" > /sys/bus/hid/drivers/hid-appletb-kbd/bind 2>/dev/null || true
                fi
            done

            # Restore keyboard backlight if available
            for kbd in /sys/class/leds/*kbd_backlight*/brightness; do
                if [[ -f "$kbd" ]]; then
                    echo "${toString cfg.keyboardBacklightLevel}" > "$kbd" 2>/dev/null || true
                fi
            done
            ;;
    esac
  '';
in {
  options.hardware.apple-t2-suspend = {
    enable = lib.mkEnableOption "T2 Mac suspend/resume fixes";

    keyboardBacklightLevel = lib.mkOption {
      type = lib.types.int;
      default = 100;
      description = "Keyboard backlight level to restore after resume (0-255)";
    };

    useDeepSleep = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use deep (S3) sleep mode instead of s2idle";
    };

    disableAspm = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable PCIe ASPM (may help with suspend stability on some systems)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Kernel parameters for proper suspend
    boot.kernelParams =
      lib.optionals cfg.useDeepSleep ["mem_sleep_default=deep"]
      ++ lib.optionals cfg.disableAspm ["pcie_aspm=off"];

    # Systemd service for suspend/resume handling
    systemd.services.suspend-fix-t2 = {
      description = "T2 Mac suspend/resume fixes (Wi-Fi, Bluetooth, Touch Bar)";
      before = ["sleep.target"];
      wantedBy = ["sleep.target"];

      unitConfig = {
        StopWhenUnneeded = true;
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStopSec = 60;
        ExecStart = "${suspendScript} pre";
        ExecStop = "${suspendScript} post";
      };
    };

    # Ensure power management is enabled (required for post-resume.service)
    powerManagement.enable = true;
  };
}
