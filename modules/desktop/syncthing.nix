{...}: {
  flake.modules.nixos.syncthing = {lib, ...}: {
    systemd.tmpfiles.rules = [
      "d /home/job/syncthing 0750 job users - -"
      "d /home/job/syncthing/obsidian_vault 0750 job users - -"
      "f+ /home/job/syncthing/obsidian_vault/.stignore 0600 job users - ${lib.concatStringsSep "\\n" (import ../_obsidian-stignore.nix)}"
    ];

    services.syncthing = {
      enable = true;
      user = "job";
      group = "users";
      dataDir = "/home/job";
      configDir = "/home/job/.config/syncthing";
      # Keep public ports closed; use Tailscale or Syncthing relays.
      openDefaultPorts = false;
      overrideDevices = false;
      overrideFolders = false;
    };
  };

  flake.modules.darwin.syncthing = {pkgs, ...}: {
    environment.systemPackages = [pkgs.syncthing];

    # Syncthing stores its configuration in the macOS user application-support
    # directory. Pair devices and add the vault folder through its web UI.
    launchd.user.agents.syncthing = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.syncthing}/bin/syncthing"
          "serve"
          "--no-browser"
          "--no-restart"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Interactive";
      };
    };
  };
}
