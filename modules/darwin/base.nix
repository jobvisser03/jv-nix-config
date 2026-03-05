# Base Darwin (macOS) configuration
# Darwin only module - system settings and base configuration
{...}: {
  flake.modules.darwin.base = {
    pkgs,
    lib,
    config,
    ...
  }: {
    # zsh is the default shell
    programs.zsh.enable = true;

    # nix-darwin manages nix itself, so we disable it here
    nix.enable = false;

    # Touch ID for sudo
    security.pam.services.sudo_local.touchIdAuth = true;

    # System settings
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

    # This is needed for nix-darwin to work with macOS Sequoia
    ids.uids.nixbld = 31000;
  };
}
