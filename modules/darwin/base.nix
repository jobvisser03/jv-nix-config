# Base Darwin (macOS) configuration
# Darwin only module - system settings and base configuration
{...}: {
  flake.modules.darwin.base = {
    pkgs,
    lib,
    config,
    ...
  }: {
    # .NET runtime required by apps like Azure Storage Explorer
    environment.systemPackages = [ pkgs.dotnet-runtime_10 ];

    # Expose DOTNET_ROOT to GUI apps (launchd) and terminal shells (/etc/zshenv).
    # Storage Explorer's hub controller probes well-known paths; this env var
    # makes nix's nix-store-based install visible to it.
    launchd.user.envVariables.DOTNET_ROOT = "${pkgs.dotnet-runtime_10}/share/dotnet";
    environment.variables.DOTNET_ROOT = "${pkgs.dotnet-runtime_10}/share/dotnet";

    # zsh is the default shell
    programs.zsh.enable = true;

    # nix-darwin manages nix itself, so we disable it here
    nix.enable = false;

    # Touch ID for sudo
    security.pam.services.sudo_local.touchIdAuth = true;

    # System settings
    system = {
      keyboard.enableKeyMapping = true;
      keyboard.remapCapsLockToEscape = true;
      defaults = {
        dock.autohide = true;
        loginwindow.GuestEnabled = false;
        NSGlobalDomain.AppleICUForce24HourTime = true;
        "com.apple.keyboard.fnState" = true; # Use F1, F2, etc. keys as standard function keys.
	      "com.apple.sound.beep.volume" = 0.4723665; # 25%
        NSGlobalDomain.KeyRepeat = 2;
        NSGlobalDomain.InitialKeyRepeat = 15; 
        ApplePressAndHoldEnabled = false; # When holding a char like e, we will not get a prompt for special chars like: è, ë etc.
      };
      stateVersion = 5;
    };

    # This is needed for nix-darwin to work with macOS Sequoia
    ids.uids.nixbld = 31000;
  };
}
