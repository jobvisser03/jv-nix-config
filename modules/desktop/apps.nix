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

  # Cross-platform home-manager packages (works on both NixOS and Darwin)
  flake.modules.homeManager.desktop-apps = {
    pkgs,
    lib,
    inputs,
    ...
  }: let
    packages = with pkgs; [
      # Core CLI tools
      curl
      ffmpeg
      fzf
      hurl
      yt-dlp
      fastfetch

      # CLI maintenance
      # scan folders and files for cleanup using a rust implementation of du
      dust

      # Languages and formatters
      nil
      alejandra
      shfmt

      # Shells and terminals
      pkgs.unstable.vim
      pkgs.unstable.helix
      pkgs.unstable.wezterm

      # Fonts
      (nerd-fonts.caskaydia-cove)
      (nerd-fonts.fantasque-sans-mono)
      (nerd-fonts.sauce-code-pro)

      # Cloud and networking
      google-cloud-sdk
      azure-cli
      azure-storage-azcopy
      cachix
      tailscale
      speedtest-cli

      # DevOps & CI/CD
      glab

      # Android and Docker
      android-tools

      # Graph visualization
      graphviz

      # Image manipulation
      imagemagick

      # Development tools (unstable: moves faster than the stable base)
      pkgs.unstable.devenv

      # TUI coding apps
      pkgs.unstable.opencode
      pkgs.unstable.claude-code
      inputs.herdr.packages.${pkgs.system}.default
      # pi-coding-agent is managed by modules/dev/pi.nix (pi.nix flake)

      # Reduce LLM token consumption
      pkgs.unstable.rtk

      # Desktop applications
      # keepassxc # moved to homebrew (qtmacextras/cctools linker crash)
      proton-pass
      drawio
      anki-bin
      docker-client
      sops
      ssh-to-age
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
