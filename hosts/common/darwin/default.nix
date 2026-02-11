# Common Darwin (macOS) system configuration
{pkgs, ...}: {
  homebrew = {
    enable = true;
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    onActivation.cleanup = "uninstall";

    brews = [
      "cowsay"
      "hashicorp/tap/vault"
      "azure-cli"
      "docker-credential-helper"
    ];
    casks = [
      "signal"
      "whatsapp"
      "beeper"
      "brave-browser"
      "raycast"
      "logseq"
      "cryptomator"
      "darktable"
      "macfuse"
      "rancher"
      "cursor"
      "visual-studio-code"
      "microsoft-azure-storage-explorer"
      "qobuz"
      "proton-mail"
      "keepassxc"
      "slack"
      "obs"
      "opencode-desktop"
    ];
    taps = ["hashicorp/tap"];
  };

  programs.zsh.enable = true;
  nix.enable = false;

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
}
