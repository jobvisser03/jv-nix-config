# Common Darwin (macOS) system configuration
{lib, ...}: {
  flake.modules.darwin.common = {
    config,
    pkgs,
    ...
  }: {
    programs.zsh.enable = true;

    # Use Determinate Nix or external nix installation
    nix.enable = false;

    # Touch ID for sudo
    security.pam.services.sudo_local.touchIdAuth = true;

    system = {
      keyboard.enableKeyMapping = true;
      keyboard.remapCapsLockToEscape = true;
      defaults = {
        dock.autohide = true;
        loginwindow.GuestEnabled = false;
        NSGlobalDomain.AppleICUForce24HourTime = true;
        NSGlobalDomain.KeyRepeat = 1;
        NSGlobalDomain.InitialKeyRepeat = 14;
      };
      stateVersion = 5;
    };
  };
}
