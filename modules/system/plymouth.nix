# Graphical boot splash + silent boot (https://wiki.nixos.org/wiki/Plymouth)
# NixOS only module. Stylix's plymouth target themes the splash.
# Press Esc during boot to see the log; hold Space for the boot menu.
{...}: {
  flake.modules.nixos.plymouth = {lib, ...}: {
    boot = {
      plymouth.enable = true;

      consoleLogLevel = 3;
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "rd.udev.log_level=3"
        "rd.systemd.show_status=auto"
      ];

      loader.timeout = lib.mkDefault 0;
    };
  };
}
