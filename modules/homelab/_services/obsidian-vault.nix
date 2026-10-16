# Obsidian vault replica on a headless host: Syncthing plus a local git history.
#
# Devices and the folder are paired in the Syncthing UI, as on the other hosts.
# See docs/syncthing-obsidian.md.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.obsidian-vault;
  stignore = import ../../_obsidian-stignore.nix;
in {
  options.homelab.services.obsidian-vault = {
    enable = lib.mkEnableOption "Syncthing replica of the Obsidian vault";

    user = lib.mkOption {
      type = lib.types.str;
      description = "User Syncthing runs as; owns the vault files.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      description = "Group of the vault files.";
    };

    dir = lib.mkOption {
      type = lib.types.str;
      example = "/var/lib/hermes/workspace/obsidian_vault";
      description = "Vault path. Set the Syncthing folder path to this when accepting it.";
    };

    autocommit = {
      enable =
        lib.mkEnableOption "periodic commits of the vault to a local git repo (`/.git` is not synced)"
        // {default = true;};

      interval = lib.mkOption {
        type = lib.types.str;
        default = "15min";
        description = "Time between commits (systemd time span).";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      inherit (cfg) user group;
      dataDir = config.users.users.${cfg.user}.home;
      configDir = "${config.users.users.${cfg.user}.home}/.config/syncthing";
      # Peers reach it over Tailscale (tailscale0 is trusted); GUI via SSH tunnel.
      openDefaultPorts = false;
      overrideDevices = false;
      overrideFolders = false;
    };

    # .stignore is not synced, so every host writes its own.
    systemd.tmpfiles.rules = [
      "d ${cfg.dir} 0750 ${cfg.user} ${cfg.group} - -"
      "f+ ${cfg.dir}/.stignore 0600 ${cfg.user} ${cfg.group} - ${lib.concatStringsSep "\\n" stignore}"
    ];

    # The repo is owned by cfg.user; let other users (e.g. the admin, via the
    # group) run read-only git commands without the "dubious ownership" error.
    programs.git = lib.mkIf cfg.autocommit.enable {
      enable = true;
      config.safe.directory = [cfg.dir];
    };

    # Local history of every change (local or synced), so a bad edit can be
    # reverted. /.git is in .stignore, so the repo stays on this host.
    systemd.services.obsidian-vault-autocommit = lib.mkIf cfg.autocommit.enable {
      description = "Commit Obsidian vault changes to its local git history";
      unitConfig.ConditionPathIsDirectory = cfg.dir;
      path = [pkgs.git];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dir;
      };
      script = ''
        [ -d .git ] || git init -q -b main
        # Syncthing markers and in-flight temp files; local, not committed.
        printf '%s\n' /.stfolder /.stversions/ '.syncthing.*.tmp' '~syncthing~*.tmp' > .git/info/exclude
        git add -A
        git diff --cached --quiet && exit 0
        git -c user.name=${cfg.user} -c user.email=${cfg.user}@${config.networking.hostName} \
          commit -q -m "auto: $(git diff --cached --name-only | wc -l) files"
      '';
    };
    systemd.timers.obsidian-vault-autocommit = lib.mkIf cfg.autocommit.enable {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = cfg.autocommit.interval;
      };
    };
  };
}
