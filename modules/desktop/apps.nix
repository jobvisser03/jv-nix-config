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

  # Cross-platform home-manager packages (works on both NixOS and Darwin)
  flake.modules.homeManager.desktop-apps = {pkgs, ...}: {
    home.packages = with pkgs; [
      # Core CLI tools
      curl
      ffmpeg
      fzf
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
      sops
    ];

    programs.vscode = {
      enable = true;
    };
  };

  # NixOS-only home-manager packages (Linux-specific applications)
  flake.modules.homeManager.nixos-desktop-apps = {pkgs, ...}: {
    home.packages = with pkgs; [
      # Linux-only desktop applications
      nautilus
      spotify
      retroarch-free
    ];

    programs.vscode = {
      package = pkgs.vscode.fhs;
    };
  };
}
