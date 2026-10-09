# Base NixOS configuration
# NixOS only module - system settings and base configuration
{...}: {
  flake.modules.nixos.base = {
    pkgs,
    lib,
    config,
    username,
    inputs,
    ...
  }: {
    # Timezone and locale
    time.timeZone = lib.mkDefault "Europe/Amsterdam";
    i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

    # Networking
    networking.networkmanager.enable = lib.mkDefault true;

    # Avahi for local network discovery
    services.avahi = {
      enable = lib.mkDefault true;
      nssmdns4 = lib.mkDefault true;
      publish = {
        enable = lib.mkDefault true;
        addresses = lib.mkDefault true;
        workstation = lib.mkDefault true;
      };
    };

    # SSH
    services.openssh.enable = lib.mkDefault true;

    # VSCode Remote SSH
    programs.vscodeRemoteSSH.enable = lib.mkDefault true;

    # Tailscale VPN
    services.tailscale = {
      enable = lib.mkDefault true;
      useRoutingFeatures = lib.mkDefault "client";
    };

    # Run unpatched binaries (pip wheels, uv tools, vendor CLIs). Extra
    # libraries for VS Code Server are added in vscode-server.nix.
    programs.nix-ld.enable = lib.mkDefault true;
    # Populates /bin and /usr/bin so `#!/bin/bash`-style shebangs work
    services.envfs.enable = lib.mkDefault true;

    # Don't hang for 90s on "a stop job is running" at shutdown
    systemd.settings.Manager.DefaultTimeoutStopSec = "10s";

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Exposes pkgs.unstable.<pkg> for dev tools that want to move faster
    # than the stable 26.05 base (see modules/flake/overlays.nix)
    nixpkgs.overlays = [inputs.self.overlays.unstable-packages];

    # Default state version
    system.stateVersion = lib.mkDefault "25.11";
  };
}
