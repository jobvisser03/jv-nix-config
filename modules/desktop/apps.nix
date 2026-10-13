# Desktop applications module for NixOS and Darwin desktop systems
# Provides common desktop applications not covered by other specific modules
# Shared desktop services are configured in desktop-base; Hyprland session
# services are configured in hyprland.nix.
{...}: {
  flake.modules.nixos.desktop-apps = {pkgs, ...}: let
    # Override with latest Electron to avoid EOL security warnings
    logseq = pkgs.logseq.override {
      electron_39 = pkgs.electron_41;
    };
  in {
    # AirDrop-style LAN file sharing; also opens its firewall port (53317)
    programs.localsend.enable = true;

    environment.systemPackages = with pkgs; [
      # Hardware management
      radeontop

      # Browsers (brave as secondary, firefox handled by its own module)
      brave

      # Desktop applications
      # logseq
      cryptomator
      signal-desktop

      # Office
      onlyoffice-desktopeditors

      # Wallpaper daemon
      awww
    ];
  };

  # Cross-platform GUI apps and fonts (works on both NixOS and Darwin).
  # Terminal tools live in cli-apps (modules/dev/cli-apps.nix).
  flake.modules.homeManager.desktop-apps = {
    pkgs,
    lib,
    ...
  }: let
    packages = with pkgs; [
      # Terminals
      pkgs.unstable.wezterm

      # Fonts
      (nerd-fonts.caskaydia-cove)
      (nerd-fonts.fantasque-sans-mono)
      (nerd-fonts.sauce-code-pro)

      # Android
      android-tools

      # Desktop applications
      # keepassxc # moved to homebrew (qtmacextras/cctools linker crash)
      proton-pass
      drawio
      anki-bin
      darktable
    ];
  in {
    home.packages =
      builtins.filter (pkg: lib.meta.availableOn pkgs.stdenv.hostPlatform pkg)
      packages;
  };

  # NixOS-only home-manager packages (Linux-specific applications)
  flake.modules.homeManager.nixos-desktop-apps = {pkgs, ...}: {
    home.packages = with pkgs; [
      # Linux-only desktop applications
      nautilus
      spotify
      retroarch-free
    ];
  };
}
