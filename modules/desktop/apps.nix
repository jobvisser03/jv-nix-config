# Desktop applications module for NixOS and Darwin desktop systems
# Provides common desktop applications not covered by other specific modules
# Services (greetd, pipewire, etc.) are configured in hyprland.nix
{...}: {
  flake.modules.nixos.desktop-apps = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      # Hardware management
      radeontop
      easyeffects
      helvum

      # Browsers (brave as secondary, firefox handled by its own module)
      brave

      # Desktop applications
      logseq
      cryptomator
      protonmail-desktop
      signal-desktop

      # Wallpaper daemon
      swww
    ];
  };

  flake.modules.homeManager.desktop-apps = {pkgs, ...}: {
    home.packages = with pkgs; [
      # Core CLI tools
      curl
      ffmpeg
      fzf
      rsync
      hurl
      yt-dlp
      neofetch

      # Languages and formatters
      nil

      # Shells and terminals
      vim
      helix
      wezterm

      # Fonts
      (nerd-fonts.caskaydia-cove)
      (nerd-fonts.fantasque-sans-mono)
      (nerd-fonts.sauce-code-pro)

      # Cloud and networking
      google-cloud-sdk
      cachix
      tailscale
      speedtest-cli

      # Android and Docker
      android-tools

      # Graph visualization
      graphviz

      # Image manipulation
      imagemagick

      # Development tools
      nodejs_22
      devenv

      # opencode CLI
      opencode

      # Desktop applications
      keepassxc
      drawio
      anki-bin
      docker-client
      overskride
      nautilus
      sops
      spotify
    ];

    programs.vscode = {
      enable = true;
      package = pkgs.vscode.fhs;
    };
  };
}
