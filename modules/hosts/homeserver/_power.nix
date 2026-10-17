# Idle power tuning for the always-on homeserver. SATA link power management
# is already med_power_with_dipm by default. PCIe ASPM is left alone: the
# onboard Realtek r8169 carries the initrd network unlock.
{...}: {
  # Disable NMI watchdog - saves ~1W
  boot.kernel.sysctl."kernel.nmi_watchdog" = 0;

  # amd-pstate-epp defaults to balance_performance; balance_power still boosts
  # under load but idles lower.
  systemd.tmpfiles.rules = [
    "w /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference - - - - balance_power"
  ];
}
