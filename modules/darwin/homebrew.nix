# Homebrew configuration for Darwin
{lib, ...}: {
  flake.modules.darwin.homebrew = {
    config,
    pkgs,
    ...
  }: {
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
  };
}
