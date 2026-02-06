{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  # Desktop-specific configuration that can be shared across desktop systems

  # Common desktop packages
  environment.systemPackages = with pkgs; [
    dunst
    libnotify

    # Manage hardware
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

    # Development tools commonly used on desktop
    git
    vim
    code-cursor
    vscode.fhs
    nodejs_latest # Node.js 24 with npm

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
    dunst
    libnotify
    tuigreet
  ];

  # Common desktop programs for home-manager
  programs = {
    zsh.enable = true;
    firefox.enable = true;
    hyprlock.enable = true;
  };

  services.pulseaudio.enable = false;

  # Common desktop services
  services = {
    # Enable printing
    printing.enable = true;

    # Enable sound with pipewire
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # Enable touchpad support
    libinput.enable = true;

    # Display manager configuration
    displayManager.defaultSession = "hyprland";

    hypridle.enable = true;

    # Bluetooth manager
    blueman.enable = true;

    # Greetd display manager
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --remember --asterisks --cmd ${pkgs.hyprland}/bin/start-hyprland";
          user = "greeter";
        };
      };
    };

    # X11 keyboard configuration
    xserver.xkb = {
      layout = "us";
      options = "caps:escape,ctrl:swap_lwin_lctl";
    };

    # Set AMD GPU driver
    xserver.videoDrivers = ["amdgpu"];
  };

  # Hardware support
  hardware = {
    # Enable OpenGL
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Enable bluetooth
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # Console configuration
  console = {
    useXkbConfig = true; # use xkb.options in tty.
  };

  # Security and system settings
  security.rtkit.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Environment variables for Wayland/Hyprland
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    ELECTRON_ENABLE_WAYLAND = "1";
    ELECTRON_NO_SANDBOX = "1";
  };

  # Create greeter user
  users.users.greeter = {
    isNormalUser = false;
    description = "greetd greeter user";
    extraGroups = ["video" "audio"];
    linger = true;
  };
}
