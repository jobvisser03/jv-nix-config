{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    # Import window manager home configurations
    ../modules/wm/hyprland.nix # Assuming you have hyprland home config
  ];

  # Linux-specific home configuration
  home.packages = with pkgs; [
    # Linux desktop applications
    discord
    slack
    telegram-desktop

    # Linux-specific utilities
    xclip
    wl-clipboard

    # File managers
    nautilus

    # Terminal applications
    alacritty
    kitty
  ];

  # XDG configuration
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # Desktop-specific settings
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "Adwaita-dark";
      icon-theme = "Adwaita";
    };
  };
}
