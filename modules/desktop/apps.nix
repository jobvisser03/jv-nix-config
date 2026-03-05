# Desktop applications module for NixOS desktop systems
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

      # Development tools
      vscode.fhs
      code-cursor
      nodejs_22
      devenv

      # Desktop applications
      logseq
      pcloud
      keepassxc
      cryptomator
      protonmail-desktop
      signal-desktop

      # Wallpaper daemon
      swww
    ];
  };
}
