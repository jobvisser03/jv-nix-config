# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./cachix.nix
    ./stylix.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  hardware.firmware = [
    (pkgs.stdenvNoCC.mkDerivation (final: {
      name = "brcm-firmware";
      src = ./firmware/brcm;
      installPhase = ''
        mkdir -p $out/lib/firmware/brcm
        cp ${final.src}/* "$out/lib/firmware/brcm"
      '';
    }))
  ];

  networking.hostName = "job-mac-nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  services.displayManager.defaultSession = "hyprland";

  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  #services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    logseq
    pcloud
    code-cursor
    brave
    keepassxc
    cryptomator
    protonmail-desktop
    signal-desktop
    vscode.fhs
    hyprlock
    hypridle
    waybar
    swww
    kitty
    rofi-wayland
    #waybar.overrideAttrs (oldAttrs: {
    #  mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
    #})
    dunst
    libnotify
    greetd.tuigreet
  ];

  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "caps:escape";

  # Also configure console keymap for TTY
  console = {
    # keyMap = "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.job = {
    isNormalUser = true;
    extraGroups = ["wheel" "video" "audio" "networkmanager"]; # Enable 'sudo' for the user.
    packages = with pkgs; [
      tree
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;

  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  boot.loader.timeout = 0;

  programs.hyprlock.enable = true;
  services.hypridle.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # set the flake package
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    # doesnt work with cursor, does work with the rest
    NIXOS_OZONE_WL = "1";

    # Fix Electron apps (like Cursor) scaling and rendering on Wayland
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    # Force Electron apps to use Wayland
    ELECTRON_ENABLE_WAYLAND = "1";
    # Disable GPU sandbox for better compatibility
    ELECTRON_NO_SANDBOX = "1";
  };

  hardware = {
    graphics.enable = true;
    nvidia.modesetting.enable = false;
  };

  xdg.portal.enable = true;
  # xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];

  # Enable Display Manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --remember --asterisks --cmd Hyprland";
        user = "greeter";
      };

      initial_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = "job";
      };
    };
  };

  users.users.greeter = {
    isNormalUser = false;
    description = "greetd greeter user";
    extraGroups = ["video" "audio"];
    linger = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
