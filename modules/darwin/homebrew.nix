# Darwin only module
{...}: {
  flake.modules.darwin.homebrew = {
    pkgs,
    lib,
    config,
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
        # "cursor"
        # "opencode-desktop"
        "visual-studio-code"
        "microsoft-azure-storage-explorer"
        # "qobuz"
        # "proton-mail"
        "proton-pass"
        # "keepassxc"
        # "slack"
        # "obs"
        "handy"
      ];

      taps = ["hashicorp/tap"];
    };
  };
}
