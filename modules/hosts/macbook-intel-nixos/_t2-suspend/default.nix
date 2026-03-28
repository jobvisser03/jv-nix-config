# T2 Mac suspend/resume fix module
# Based on:
# - https://github.com/t2linux/T2-Debian-and-Ubuntu-Kernel/issues/53
# - https://github.com/lucadibello/T2Linux-Suspend-Fix (PipeWire + apple-bce insight)
# - https://github.com/benstaker/T2Linux-Suspend-Fix (v1.5.0 - full driver teardown)
#
# Key insights:
# - lucadibello: PipeWire holds PCM stream handles to apple-bce's audio device.
#   On resume, apple-bce maps audio at a NEW MMIO address, causing kernel panics.
# - benstaker: Full driver teardown (bluetooth, touch bar, sparse_keymap) + PCI
#   rescan on resume + separate resume service for reliability + IOMMU/PCIe compat
#   kernel params.
#
# Future: https://github.com/deqrocks/apple-bce (no-state-suspend branch)
#   proposes in-driver PM callbacks that rebuild USB controller state on resume,
#   eliminating the need for module unload/reload and PipeWire teardown.
#   Not yet stable as of 2026-03-28.
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

    # Get first active user session
    uid=$(${pkgs.systemd}/bin/loginctl list-sessions --no-legend 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $2}' | head -n1)
    if [ -z "$uid" ]; then
      echo "SKIP: no user session found"
      exit 0
    fi

    if [ ! -S "/run/user/$uid/bus" ]; then
      echo "SKIP: no D-Bus session found for uid $uid"
      exit 0
    fi

    user=$(${pkgs.coreutils}/bin/id -nu "$uid" 2>/dev/null) || exit 0
    echo "Stopping PipeWire for user: $user (UID: $uid)"

    XDG_RUNTIME_DIR="/run/user/$uid" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
      ${pkgs.util-linux}/bin/runuser -u "$user" -- \
      ${pkgs.systemd}/bin/systemctl --user stop \
        pipewire.socket pipewire-pulse.socket \
        pipewire.service pipewire-pulse.service \
        wireplumber.service 2>/dev/null || true

    sleep 1
    echo "PipeWire stopped for user $user"
  '';

  # Helper script to start PipeWire for all logged-in users
  startAudioScript = pkgs.writeShellScript "t2-start-audio.sh" ''
    set -euo pipefail

    uid=$(${pkgs.systemd}/bin/loginctl list-sessions --no-legend 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $2}' | head -n1)
    if [ -z "$uid" ]; then
      echo "SKIP: no user session found"
      exit 0
    fi

    if [ ! -S "/run/user/$uid/bus" ]; then
      echo "SKIP: no D-Bus session found for uid $uid"
      exit 0
    fi

    user=$(${pkgs.coreutils}/bin/id -nu "$uid" 2>/dev/null) || exit 0
    echo "Starting PipeWire for user: $user (UID: $uid)"

    XDG_RUNTIME_DIR="/run/user/$uid" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
      ${pkgs.util-linux}/bin/runuser -u "$user" -- \
      ${pkgs.systemd}/bin/systemctl --user start \
        pipewire.socket pipewire-pulse.socket 2>/dev/null || true

    echo "PipeWire sockets started for user $user"
  '';

  # Pre-suspend script
  suspendScript = pkgs.writeShellScript "t2-suspend.sh" ''
    set -euo pipefail
    echo "=== T2 Suspend: Pre-suspend sequence starting ==="

    # 1. Disable async PM operations for more reliable suspend
    echo "Setting pm_async=0..."
    echo 0 > /sys/power/pm_async

    # 2. Force deep sleep mode
    echo "Setting deep sleep mode..."
    echo deep > /sys/power/mem_sleep 2>/dev/null || true

    # 3. Stop PipeWire to release audio handles (CRITICAL)
    ${lib.optionalString cfg.stopAudio ''
    echo "Stopping PipeWire audio services..."
    ${stopAudioScript}
    ''}

    # 4. Disable WiFi radio via NetworkManager
    echo "Disabling WiFi radio..."
    ${pkgs.networkmanager}/bin/nmcli radio wifi off 2>/dev/null || true

    # 5. Block WiFi and Bluetooth
    echo "Blocking WiFi and Bluetooth..."
    ${pkgs.util-linux}/bin/rfkill block wifi 2>/dev/null || true
    ${pkgs.util-linux}/bin/rfkill block bluetooth 2>/dev/null || true

    # 6. Unload WiFi modules
    echo "Unloading WiFi modules..."
    ${pkgs.kmod}/bin/modprobe -r brcmfmac_wcc 2>/dev/null || true
    ${pkgs.kmod}/bin/modprobe -r brcmfmac 2>/dev/null || true

    # 7. Unload Bluetooth driver
    echo "Unloading Bluetooth driver..."
    ${pkgs.kmod}/bin/modprobe -r hci_bcm4377 2>/dev/null || true

    # 8. Unload Touch Bar drivers (order matters: sparse_keymap depends on hid_appletb_kbd)
    echo "Unloading Touch Bar drivers..."
    ${pkgs.kmod}/bin/modprobe -r sparse_keymap 2>/dev/null || true
    ${pkgs.kmod}/bin/modprobe -r hid_appletb_kbd 2>/dev/null || true
    ${pkgs.kmod}/bin/modprobe -r hid_appletb_bl 2>/dev/null || true

    # 9. Unload apple-bce module (CRITICAL - must be after PipeWire stops)
    ${lib.optionalString cfg.unloadAppleBce ''
    echo "Unloading apple-bce module..."
    ${pkgs.kmod}/bin/rmmod -f apple-bce 2>/dev/null || true
    sleep 1
    ''}

    # 10. Disable USB wakeup to prevent T2 internal devices from triggering spurious wakes
    echo "Disabling USB wakeup sources..."
    for dev in /sys/bus/usb/devices/*/power/wakeup; do
      [ -f "$dev" ] && echo "disabled" > "$dev" 2>/dev/null || true
    done

    echo "=== T2 Suspend: Pre-suspend sequence complete ==="
  '';

  # Post-resume script
  resumeScript = pkgs.writeShellScript "t2-resume.sh" ''
    set -euo pipefail
    echo "=== T2 Resume: Post-resume sequence starting ==="

    # 1. Reload apple-bce module (CRITICAL - must be before PipeWire starts)
    ${lib.optionalString cfg.unloadAppleBce ''
    echo "Loading apple-bce module..."
    ${pkgs.kmod}/bin/modprobe apple-bce 2>/dev/null || true

    # Wait for apple-bce PCI binding (up to 15 seconds)
    echo "Waiting for apple-bce PCI binding..."
    for i in $(seq 1 15); do
      if ls /sys/bus/pci/drivers/apple-bce/*:* >/dev/null 2>&1; then
        echo "apple-bce PCI binding found (attempt $i/15)"
        break
      fi
      sleep 1
    done
    sleep 2
    ''}

    # 2. PCI bus rescan (discovers devices that disappeared during suspend)
    echo "Running PCI bus rescan..."
    echo 1 > /sys/bus/pci/rescan 2>/dev/null || true

    # 3. Load Bluetooth driver
    echo "Loading Bluetooth driver..."
    ${pkgs.kmod}/bin/modprobe hci_bcm4377 2>/dev/null || true

    # 4. Load WiFi modules
    echo "Loading WiFi modules..."
    ${pkgs.kmod}/bin/modprobe brcmfmac 2>/dev/null || true
    ${pkgs.kmod}/bin/modprobe brcmfmac_wcc 2>/dev/null || true

    # 5. Unblock WiFi and Bluetooth
    echo "Unblocking WiFi and Bluetooth..."
    ${pkgs.util-linux}/bin/rfkill unblock wifi 2>/dev/null || true
    ${pkgs.util-linux}/bin/rfkill unblock bluetooth 2>/dev/null || true

    # 6. Enable WiFi radio
    echo "Enabling WiFi radio..."
    ${pkgs.networkmanager}/bin/nmcli radio wifi on 2>/dev/null || true

    # 7. Start PipeWire (CRITICAL - must be after apple-bce loads)
    ${lib.optionalString cfg.stopAudio ''
    echo "Starting PipeWire audio services..."
    ${startAudioScript}
    ''}

    # 8. Restart UPower (sees all re-appeared PCI devices)
    echo "Restarting UPower..."
    ${pkgs.systemd}/bin/systemctl restart upower 2>/dev/null || true

    # 9. Restore keyboard backlight (poll for up to 15 seconds)
    echo "Restoring keyboard backlight..."
    for i in $(seq 1 15); do
      for kbd in /sys/class/leds/*kbd_backlight*/brightness; do
        if [ -f "$kbd" ]; then
          echo "${toString cfg.keyboardBacklightLevel}" > "$kbd" 2>/dev/null && break 2
        fi
      done
      sleep 1
    done

    # 10. Wait for WiFi driver binding
    echo "Checking WiFi driver binding..."
    for i in $(seq 1 10); do
      if ls /sys/bus/pci/drivers/brcmfmac/*:* >/dev/null 2>&1; then
        echo "WiFi driver bound (attempt $i/10)"
        break
      fi
      sleep 0.5
    done

    echo "=== T2 Resume: Post-resume sequence complete ==="
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
    # pcie_ports=compat + intel_iommu/iommu=pt from benstaker fix for T2 stability
    boot.kernelParams =
      lib.optionals cfg.useDeepSleep ["mem_sleep_default=deep"]
      ++ lib.optionals cfg.disableAspm ["pcie_aspm=off"]
      ++ [
        "pcie_ports=compat"
        "intel_iommu=on"
        "iommu=pt"
      ];

    # Disable thermald - conflicts with T2 suspend (benstaker fix)
    services.thermald.enable = lib.mkForce false;

    # Suspend service: runs pre-suspend teardown, triggered before sleep
    systemd.services.t2-suspend = {
      description = "T2 Mac pre-suspend teardown (audio, Wi-Fi, Bluetooth, Touch Bar, apple-bce)";
      before = ["sleep.target"];
      wantedBy = ["sleep.target"];

      unitConfig = {
        StopWhenUnneeded = true;
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = 30;
        ExecStart = suspendScript;
      };
    };

    # Resume service: runs post-resume reload, triggered after wake
    systemd.services.t2-resume = {
      description = "T2 Mac post-resume reload (apple-bce, Wi-Fi, Bluetooth, audio, UPower)";
      after = ["suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target"];
      wantedBy = ["suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target"];

      serviceConfig = {
        Type = "oneshot";
        TimeoutStartSec = 60;
        ExecStart = resumeScript;
      };
    };

    # Configure ACPI wakeup devices at boot
    # Only allow LID0 (lid open) and PWRB (power button) to wake the system.
    # XHC1/XHC2 (USB host controllers) cause spurious wakes on T2 Macs because
    # the T2 chip's internal USB devices (keyboard, trackpad, touch bar) trigger
    # false wake events.
    systemd.services.t2-configure-wakeup-devices = {
      description = "Configure ACPI wakeup sources for T2 Mac (LID0 + PWRB only)";
      after = ["multi-user.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "t2-configure-wakeup-devices.sh" ''
          set -euo pipefail

          # Devices that should be allowed to wake the system
          ALLOW_WAKE="LID0 PWRB"

          while IFS= read -r line; do
            dev=$(echo "$line" | ${pkgs.gawk}/bin/awk '{print $1}')
            status=$(echo "$line" | ${pkgs.gawk}/bin/awk '{print $3}')
            [ "$dev" = "Device" ] && continue
            [ -z "$dev" ] && continue

            is_allowed=false
            for allowed in $ALLOW_WAKE; do
              [ "$dev" = "$allowed" ] && is_allowed=true
            done

            if $is_allowed && [ "$status" = "*disabled" ]; then
              echo "Enabling wakeup for $dev"
              echo "$dev" > /proc/acpi/wakeup 2>/dev/null || true
            elif ! $is_allowed && [ "$status" = "*enabled" ]; then
              echo "Disabling wakeup for $dev"
              echo "$dev" > /proc/acpi/wakeup 2>/dev/null || true
            fi
          done < /proc/acpi/wakeup
        '';
      };
    };

    # Ensure power management is enabled
    powerManagement.enable = true;
  };
}
