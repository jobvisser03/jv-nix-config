# GPU mode configuration for MacBook Intel (hybrid Intel iGPU + AMD dGPU)
# igpu: Intel as primary (force_igd=y) - historically causes freezes + broken suspend
# dgpu: AMD as primary (force_igd=n) - stable, uses by-path symlinks for stable device refs
{
  config,
  lib,
  ...
}: {
  options.macbook.gpuMode = lib.mkOption {
    type = lib.types.enum ["igpu" "dgpu"];
    default = "dgpu";
  };

  config = {
    boot.extraModprobeConfig = ''
      options apple-gmux force_igd=${if config.macbook.gpuMode == "igpu" then "y" else "n"}
    '';

    boot.kernelParams =
      if config.macbook.gpuMode == "dgpu"
      then [
        # Disable amdgpu runtime PM - conflicts with apple-gmux switching
        "amdgpu.runpm=0"
        # Intel GuC not needed when dGPU is primary
        "i915.enable_guc=0"
      ]
      else [
        # Intel GuC submission for hybrid graphics suspend support
        "i915.enable_guc=3"
      ];

    # Tell Aquamarine/Hyprland which GPU to use via stable PCI by-path symlinks
    environment.sessionVariables.AQ_DRM_DEVICES =
      if config.macbook.gpuMode == "igpu"
      then "/dev/dri/by-path/pci-0000:00:02.0-card"
      else "/dev/dri/by-path/pci-0000:03:00.0-card";

    # Keep AMD at low power only when it's a background offload GPU
    services.udev.extraRules = lib.mkIf (config.macbook.gpuMode == "igpu") ''
      SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="low"
    '';
  };
}
