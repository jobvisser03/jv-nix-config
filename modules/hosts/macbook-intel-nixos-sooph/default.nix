# MacBook Intel running NixOS host definition
{...}: {
  flake.modules.nixos."hosts/macbook-intel-nixos-sooph" = {
    config,
    pkgs,
    lib,
    inputs,
    username,
    ...
  }: {
    imports = [
      # Hardware configuration
      ./hardware-configuration.nix
    ];

nixpkgs.config.allowUnfree = true;

    # Host identity
    networking.hostName = "sooph-macbook-nixos";

  networking.networkmanager.enable = true;

    # Boot configuration
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot";
      timeout = 0;
    };

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  boot.kernelModules = [
"firewire-core"
"firewire-ohci"
"firewire-net"
"wl"
];

boot.initrd.kernelModules = [ "kvm-intel" "wl" ] ;

hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
hardware.nvidia.modesetting.enable = true;
hardware.opengl.enable = true;

nixpkgs.config.permittedInsecurePackages = [
"broadcom-sta-6.30.223.271-59-6.12.75"
"broadcom-sta-6.30.223.271-59-6.12.69"
];

boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
 
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  console.useXkbConfig = true;
   services.xserver.xkb.options = "eurosign:e,caps:escape";

   services.pipewire = {
     enable = true;
     pulse.enable = true;
   };

   # Printing
      services.printing.enable = true;
   
     # Enable touchpad support (enabled default in most desktopManager).
   services.libinput.enable = true;

    # Host-specific packages
    environment.systemPackages = with pkgs; [
      tree
      git
      vim
    ];

  # Enable the OpenSSH daemon.
   services.openssh.enable = true;

    system.stateVersion = "25.11";
  };
}
