# T2 Mac suspend/resume fix module
# Based on:
# - https://github.com/t2linux/T2-Debian-and-Ubuntu-Kernel/issues/53
# - https://github.com/lucadibello/T2Linux-Suspend-Fix
# - https://github.com/deqrocks/T2Linux-Suspend-Fix
#
# The key insight from lucadibello: PipeWire holds PCM stream handles to
# apple-bce's audio device. On resume, apple-bce maps audio at a NEW MMIO
# address, but PipeWire's stale handles point to the old address, causing
# kernel panics or broken input devices.
#
# Solution: Stop PipeWire BEFORE unloading apple-bce, restart AFTER reload.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hardware.apple-t2-suspend;

  # Helper script to stop PipeWire for all logged-in users
  stopAudioScript = pkgs.writeShellScript "t2-stop-audio.sh" ''
    set -euo pipefail

    # Get all logged-in users with active sessions
    for uid in $(${pkgs.systemd}/bin/loginctl list-users --no-legend | ${pkgs.gawk}/bin/awk '{print $1}'); do
      user=$(${pkgs.coreutils}/bin/id -nu "$uid" 2>/dev/null) || continue

      echo "Stopping PipeWire for user: $user (UID: $uid)"

      # Stop PipeWire services for this user
      ${pkgs.systemd}/bin/systemctl --user -M "$user@" stop pipewire.socket 2>/dev/null || true
      ${pkgs.systemd}/bin/systemctl --user -M "$user@" stop pipewire-pulse.socket 2>/dev/null || true
      ${pkgs.systemd}/bin/systemctl --user -M "$user@" stop pipewire.service 2>/dev/null || true
      ${pkgs.systemd}/bin/systemctl --user -M "$user@" stop pipewire-pulse.service 2>/dev/null || true
      ${pkgs.systemd}/bin/systemctl --user -M "$user@" stop wireplumber.service 2>/dev/null || true
    done

    # Give services time to stop cleanly
    sleep 1
    echo "PipeWire stopped for all users"
  '';

  # Helper script to start PipeWire for all logged-in users
  startAudioScript = pkgs.writeShellScript "t2-start-audio.sh" ''
    set -euo pipefail

    # Get all logged-in users with active sessions
    for uid in $(${pkgs.systemd}/bin/loginctl list-users --no-legend | ${pkgs.gawk}/bin/awk '{print $1}'); do
      user=$(${pkgs.coreutils}/bin/id -nu "$uid" 2>/dev/null) || continue

      echo "Starting PipeWire for user: $user (UID: $uid)"

      # Start PipeWire sockets (services will be activated on demand)
      ${pkgs.systemd}/bin/systemctl --user -M "$user@" start pipewire.socket 2>/dev/null || true
      ${pkgs.systemd}/bin/systemctl --user -M "$user@" start pipewire-pulse.socket 2>/dev/null || true
    done

    echo "PipeWire started for all users"
  '';

  # Main suspend/resume script
  suspendScript = pkgs.writeShellScript "suspend-fix-t2.sh" ''
    set -euo pipefail

    case "$1" in
      pre)
        echo "=== T2 Suspend: Pre-suspend sequence starting ==="

        # 1. Disable async PM operations for more reliable suspend
        echo "Disabling async PM..."
        echo 0 > /sys/power/pm_async

        # 2. Force deep sleep mode
        echo "Setting deep sleep mode..."
        echo deep > /sys/power/mem_sleep 2>/dev/null || true

        # 3. Stop PipeWire to release audio handles (CRITICAL)
        ${lib.optionalString cfg.stopAudio ''
      echo "Stopping PipeWire audio services..."
      ${stopAudioScript}
    ''}

        # 4. Stop NetworkManager
        echo "Stopping NetworkManager..."
        ${pkgs.systemd}/bin/systemctl stop NetworkManager 2>/dev/null || true

        # 5. Block WiFi and Bluetooth
        echo "Blocking WiFi and Bluetooth..."
        ${pkgs.util-linux}/bin/rfkill block wifi 2>/dev/null || true
        ${pkgs.util-linux}/bin/rfkill block bluetooth 2>/dev/null || true

        # 6. Unload WiFi modules
        echo "Unloading WiFi modules..."
        ${pkgs.kmod}/bin/modprobe -r brcmfmac_wcc 2>/dev/null || true
        ${pkgs.kmod}/bin/modprobe -r brcmfmac 2>/dev/null || true

        # 7. Unload apple-bce module (CRITICAL - must be after PipeWire stops)
        ${lib.optionalString cfg.unloadAppleBce ''
      echo "Unloading apple-bce module..."
      ${pkgs.kmod}/bin/rmmod -f apple-bce 2>/dev/null || true
      sleep 1
    ''}

        echo "=== T2 Suspend: Pre-suspend sequence complete ==="
        ;;

      post)
        echo "=== T2 Resume: Post-resume sequence starting ==="

        # 1. Re-enable async PM operations
        echo "Re-enabling async PM..."
        echo 1 > /sys/power/pm_async

        # 2. Reload apple-bce module (CRITICAL - must be before PipeWire starts)
        ${lib.optionalString cfg.unloadAppleBce ''
      echo "Loading apple-bce module..."
      ${pkgs.kmod}/bin/modprobe apple-bce 2>/dev/null || true

      # Wait for apple-bce device to appear (up to 15 seconds)
      echo "Waiting for apple-bce device..."
      timeout=15
      while [ $timeout -gt 0 ]; do
        if [ -d /sys/bus/pci/drivers/apple-bce ]; then
          echo "apple-bce device ready"
          break
        fi
        sleep 1
        timeout=$((timeout - 1))
      done

      if [ $timeout -eq 0 ]; then
        echo "WARNING: apple-bce device did not appear within timeout"
      fi

      # Additional settle time for device initialization
      sleep 2
    ''}

        # 3. Reload WiFi modules
        echo "Loading WiFi modules..."
        ${pkgs.kmod}/bin/modprobe brcmfmac 2>/dev/null || true
        ${pkgs.kmod}/bin/modprobe brcmfmac_wcc 2>/dev/null || true

        # 4. Start PipeWire (CRITICAL - must be after apple-bce loads)
        ${lib.optionalString cfg.stopAudio ''
      echo "Starting PipeWire audio services..."
      ${startAudioScript}
    ''}

        # 5. Unblock WiFi and Bluetooth
        echo "Unblocking WiFi and Bluetooth..."
        ${pkgs.util-linux}/bin/rfkill unblock wifi 2>/dev/null || true
        ${pkgs.util-linux}/bin/rfkill unblock bluetooth 2>/dev/null || true

        # 6. Start NetworkManager
        echo "Starting NetworkManager..."
        ${pkgs.systemd}/bin/systemctl start NetworkManager 2>/dev/null || true

        # 7. Rebind Touch Bar HID driver
        echo "Rebinding Touch Bar HID driver..."
        sleep 1
        for dev in /sys/bus/hid/drivers/hid-appletb-kbd/0003:*; do
          if [[ -L "$dev" ]]; then
            devid=$(${pkgs.coreutils}/bin/basename "$dev")
            echo "$devid" > /sys/bus/hid/drivers/hid-appletb-kbd/unbind 2>/dev/null || true
            sleep 0.3
            echo "$devid" > /sys/bus/hid/drivers/hid-appletb-kbd/bind 2>/dev/null || true
          fi
        done

        # 8. Restore keyboard backlight
        echo "Restoring keyboard backlight..."
        for kbd in /sys/class/leds/*kbd_backlight*/brightness; do
          if [[ -f "$kbd" ]]; then
            echo "${toString cfg.keyboardBacklightLevel}" > "$kbd" 2>/dev/null || true
          fi
        done

        echo "=== T2 Resume: Post-resume sequence complete ==="
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
      default = true;
      description = "Disable PCIe ASPM (improves suspend stability, slightly increases power usage)";
    };

    unloadAppleBce = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Unload/reload apple-bce module around suspend (required for reliable resume)";
    };

    stopAudio = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Stop PipeWire before suspend to release audio handles (required when unloadAppleBce is true)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Kernel parameters for proper suspend
    boot.kernelParams =
      lib.optionals cfg.useDeepSleep ["mem_sleep_default=deep"]
      ++ lib.optionals cfg.disableAspm ["pcie_aspm=off"];

    # Systemd service for suspend/resume handling
    systemd.services.suspend-fix-t2 = {
      description = "T2 Mac suspend/resume fixes (audio, Wi-Fi, Bluetooth, Touch Bar)";
      before = ["sleep.target"];
      wantedBy = ["sleep.target"];

      unitConfig = {
        StopWhenUnneeded = true;
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Increase timeout for module unload/reload operations
        TimeoutStartSec = 30;
        TimeoutStopSec = 60;
        ExecStart = "${suspendScript} pre";
        ExecStop = "${suspendScript} post";
      };
    };

    # Ensure power management is enabled
    powerManagement.enable = true;
  };
}
