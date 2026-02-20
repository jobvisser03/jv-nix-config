# Desktop profile - NixOS desktop workstation configuration
{lib, ...}: {
  flake.modules.profiles.desktop = {
    config,
    pkgs,
    ...
  }: {
    # Desktop packages
    environment.systemPackages = with pkgs; [
      # Notifications
      dunst
      libnotify

      # Hardware management
      radeontop
      easyeffects
      helvum

      # Browsers
      firefox
      brave

      # Media
      vlc

      # Utilities
      file-roller
      gnome-calculator

      # Development tools
      git
      vim
      code-cursor
      vscode.fhs
      nodejs_22

      # Desktop applications
      logseq
      pcloud
      keepassxc
      cryptomator
      protonmail-desktop
      signal-desktop

      # Wayland/Hyprland utilities
      hyprlock
      hypridle
      waybar
      swww
      kitty
      rofi
      tuigreet
    ];

    # Common desktop programs
    programs = {
      firefox.enable = true;
    };

    # Services
    services = {
      printing.enable = true;
      libinput.enable = true;
    };

    # X11 keyboard configuration
    services.xserver.xkb = {
      layout = "us";
      options = "caps:escape,ctrl:swap_lwin_lctl";
    };

    # Console configuration
    console.useXkbConfig = true;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Environment variables for Wayland/Hyprland
    environment.sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      ELECTRON_ENABLE_WAYLAND = "1";
      ELECTRON_NO_SANDBOX = "1";
    };
  };
}
