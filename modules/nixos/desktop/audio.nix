# Audio configuration with PipeWire
{lib, ...}: {
  flake.modules.nixos.audio = {
    config,
    pkgs,
    ...
  }: {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}
