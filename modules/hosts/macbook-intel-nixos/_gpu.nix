# GPU mode configuration for MacBook Intel (hybrid Intel iGPU + AMD dGPU)
# igpu: Intel as primary (force_igd=y) - historically causes freezes + broken suspend
# dgpu: AMD as primary (force_igd=n) - stable, card0=AMD card1=Intel
{...}: {
  flake.modules.nixos."hosts/macbook-intel-nixos" = {lib, config, ...}: {
    options.macbook.gpuMode = lib.mkOption {
      type = lib.types.enum ["igpu" "dgpu"];
      default = "dgpu";
    };

    config = {
      boot.extraModprobeConfig = ''
        options apple-gmux force_igd=${if config.macbook.gpuMode == "igpu" then "y" else "n"}
      '';

      # Keep AMD at low power only when it's a background offload GPU
      services.udev.extraRules = lib.mkIf (config.macbook.gpuMode == "igpu") ''
        SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="low"
      '';
    };
  };
}
