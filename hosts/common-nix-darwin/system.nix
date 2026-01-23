# CommonNix-darwin system configuration for managing macos settings
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
      # "ollama"
      "slack"
      "obs"
    ];
    taps = ["hashicorp/tap"];
  };

  # add nix stuff to /etc/zshrc
  programs.zsh.enable = true;

  # disable nix-darwin's management of the Nix installation
  nix.enable = false;

  # nix = {
  #   # update nix to the latest version
  #   package = pkgs.nix;

  #   # clean the nix store
  #   gc = {
  #     automatic = lib.mkDefault true;
  #     options = lib.mkDefault "--delete-older-than 7d";
  #   };

  #   settings = {
  #     # Necessary for using flakes on this system.
  #     experimental-features = ["nix-command" "flakes"];

  #     # Cachix is apparently a cache that most people use, but putting it here does not seem to do a lot
  #     substituters = ["https://nix-community.cachix.org"];
  #     trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
  #     builders-use-substitutes = true;
  #     trusted-users = ["root" "job.visser"];
  #   };
  # };
  # enable sudo with touch id
  security.pam.services.sudo_local.touchIdAuth = true;

  # set some system defaults
  system = {
    keyboard.enableKeyMapping = true;
    keyboard.remapCapsLockToEscape = true;
    defaults = {
      dock.autohide = true;
      # dock.largesize = 64;
      # dock.persistent-apps = [
      #   "${pkgs.alacritty}/Applications/Alacritty.app"
      #   "/Applications/Firefox.app"
      #   "${pkgs.obsidian}/Applications/Obsidian.app"
      #   "/System/Applications/Mail.app"
      #   "/System/Applications/Calendar.app"
      # ];
      # finder.FXPreferredViewStyle = "clmv";
      loginwindow.GuestEnabled = false;
      NSGlobalDomain.AppleICUForce24HourTime = true;
      # NSGlobalDomain.AppleInterfaceStyle = "Dark";
      NSGlobalDomain.KeyRepeat = 1;
      NSGlobalDomain.InitialKeyRepeat = 14;
    };

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 5;
  };
}
