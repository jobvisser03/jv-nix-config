# Handy speech-to-text module (Parakeet model, selected manually in-app).
# Push-to-talk runs through a Niri keybind calling `handy --toggle-transcription`
# (see modules/desktop/niri.nix), so the background instance stays hidden.
{inputs, ...}: {
  flake.modules.homeManager.handy = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [inputs.handy.homeManagerModules.default];

    services.handy.enable = true;

    # Wayland-native typing tool; enigo's fallback is unreliable under niri.
    # Select "wtype" as typing tool in Handy's settings.
    home.packages = [pkgs.wtype];

    systemd.user.services.handy.Service.ExecStart =
      lib.mkForce "${lib.getExe config.services.handy.package} --start-hidden";
  };
}
