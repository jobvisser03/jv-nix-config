# Bluetooth configuration
{lib, ...}: {
  flake.modules.nixos.bluetooth = {
    config,
    pkgs,
    ...
  }: {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services.blueman.enable = true;
  };
}
