{...}: {
  flake.modules.nixos.syncthing = {...}: {
    systemd.tmpfiles.rules = [
      "d /home/job/syncthing 0750 job users - -"
      "d /home/job/syncthing/obsidian_vault 0750 job users - -"
      # Keep editor caches and machine-specific Nix plugin links off Android.
      "f+ /home/job/syncthing/obsidian_vault/.stignore 0600 job users - /.obsidian/cache\\n/.obsidian/workspace*.json\\n/.obsidian/plugins\\n/.obsidian/community-plugins.json"
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
}
