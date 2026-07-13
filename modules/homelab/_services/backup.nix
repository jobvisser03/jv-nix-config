# Encrypted local and off-site backups for persistent homelab state
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.backup;
  ha = config.homelab.services.homeassistant;
  stagingDir = "${cfg.stagingDir}/homeassistant/current";
  localJob = "homeassistant-local";
  offsiteJob = "homeassistant-offsite";
  metricsDir = "/var/lib/prometheus-node-exporter-text-files";
  stateDir = "/var/lib/homelab-backup";
  retention = [
    "--keep-daily 14"
    "--keep-weekly 8"
    "--keep-monthly 12"
    "--keep-yearly 3"
  ];
  mkSuccessMetricService = job: {
    description = "Record successful ${job} backup metric";
    serviceConfig.Type = "oneshot";
    script = ''
      now="$(${pkgs.coreutils}/bin/date +%s)"
      tmp="${metricsDir}/backup-${job}.prom.tmp"
      printf 'homelab_backup_last_success_timestamp_seconds{job="${job}"} %s\n' "$now" > "$tmp"
      ${pkgs.coreutils}/bin/mv "$tmp" "${metricsDir}/backup-${job}.prom"
      printf '%s\n' "$now" > "${stateDir}/${job}.success"
    '';
  };
in {
  options.homelab.services.backup = {
    enable = lib.mkEnableOption "encrypted backups of homelab application state";

    passwordFile = lib.mkOption {
      type = lib.types.path;
      description = "File containing Restic repository password";
    };

    stagingDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/backup";
      description = "Local staging directory for consistent application snapshots";
    };

    homeassistant.enable = lib.mkEnableOption "Home Assistant state backups";

    local = {
      enable = lib.mkEnableOption "backup to a locally mounted filesystem";
      repository = lib.mkOption {
        type = lib.types.path;
        default = "/mnt/usb-drive/Backups/Restic/larkbox-homeassistant";
        description = "Local Restic repository";
      };
      mountPoint = lib.mkOption {
        type = lib.types.path;
        default = "/mnt/usb-drive";
        description = "Mount that must exist before local backup starts";
      };
    };

    offsite = {
      enable = lib.mkEnableOption "backup through Restic's rclone backend";
      repository = lib.mkOption {
        type = lib.types.str;
        default = "rclone:pcloud:Backups/Restic/larkbox-homeassistant";
        description = "Off-site Restic repository";
      };
      rcloneConfigFile = lib.mkOption {
        type = lib.types.path;
        description = "Rclone configuration file";
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.homeassistant.enable) {
    assertions = [
      {
        assertion = ha.enable;
        message = "Home Assistant backup requires homelab.services.homeassistant.enable";
      }
      {
        assertion = cfg.local.enable || cfg.offsite.enable;
        message = "Enable at least one Home Assistant backup destination";
      }
    ];

    environment.systemPackages = [pkgs.restic];

    systemd.tmpfiles.rules = [
      "d ${cfg.stagingDir}/homeassistant 0700 root root - -"
      "d ${stateDir} 0700 root root - -"
      "d ${metricsDir} 0755 root root - -"
    ];

    # Textfile collector exposes backup freshness without opening another port.
    services.prometheus.exporters.node.extraFlags = lib.mkIf config.homelab.services.prometheus.enable [
      "--collector.textfile.directory=${metricsDir}"
    ];

    services.restic.backups =
      lib.optionalAttrs cfg.local.enable {
        ${localJob} = {
          initialize = true;
          repository = toString cfg.local.repository;
          passwordFile = cfg.passwordFile;
          paths = [stagingDir];
          exclude = [
            "home-assistant.log*"
            "__pycache__"
            "deps"
            "tts"
          ];
          timerConfig = {
            OnCalendar = "*-*-* 04:30:00";
            Persistent = true;
            RandomizedDelaySec = "15m";
          };
          pruneOpts = retention;
          backupPrepareCommand = ''
            #!${pkgs.runtimeShell}
            set -euo pipefail

            test -d ${lib.escapeShellArg ha.configDir}
            ${pkgs.systemd}/bin/systemctl stop podman-homeassistant.service
            restart_services() {
              if ${lib.boolToString ha.zigbee2mqtt.enable}; then
                ${pkgs.systemd}/bin/systemctl start podman-zigbee2mqtt.service || true
              fi
              ${pkgs.systemd}/bin/systemctl start podman-homeassistant.service || true
            }
            trap restart_services EXIT
            if ${lib.boolToString ha.zigbee2mqtt.enable}; then
              ${pkgs.systemd}/bin/systemctl stop podman-zigbee2mqtt.service
            fi

            ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg "${stagingDir}/homeassistant"}
            ${pkgs.rsync}/bin/rsync -a --delete \
              --exclude='home-assistant.log*' \
              --exclude='__pycache__/' \
              --exclude='deps/' \
              --exclude='tts/' \
              ${lib.escapeShellArg "${ha.configDir}/"} ${lib.escapeShellArg "${stagingDir}/homeassistant/"}

            if ${lib.boolToString ha.zigbee2mqtt.enable}; then
              ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg "${stagingDir}/zigbee2mqtt"}
              ${pkgs.rsync}/bin/rsync -a --delete \
                ${lib.escapeShellArg "${ha.zigbee2mqtt.configDir}/"} ${lib.escapeShellArg "${stagingDir}/zigbee2mqtt/"}
            fi

            db=${lib.escapeShellArg "${stagingDir}/homeassistant/home-assistant_v2.db"}
            if [ -f "$db" ]; then
              result="$(${pkgs.sqlite}/bin/sqlite3 "$db" 'PRAGMA integrity_check;')"
              test "$result" = ok
            fi

            ${pkgs.coreutils}/bin/date +%s > ${lib.escapeShellArg "${cfg.stagingDir}/homeassistant/snapshot.timestamp"}
            trap - EXIT
            restart_services
          '';
        };
      }
      // lib.optionalAttrs cfg.offsite.enable {
        ${offsiteJob} = {
          initialize = true;
          repository = cfg.offsite.repository;
          passwordFile = cfg.passwordFile;
          rcloneConfigFile = cfg.offsite.rcloneConfigFile;
          paths = [stagingDir];
          timerConfig = {
            OnCalendar = "*-*-* 05:15:00";
            Persistent = true;
            RandomizedDelaySec = "15m";
          };
          pruneOpts = retention;
          backupPrepareCommand = ''
            #!${pkgs.runtimeShell}
            set -euo pipefail
            timestamp=${lib.escapeShellArg "${cfg.stagingDir}/homeassistant/snapshot.timestamp"}
            local_success=${lib.escapeShellArg "${stateDir}/${localJob}.success"}
            test -s "$timestamp"
            ${lib.optionalString cfg.local.enable ''
              test -s "$local_success"
              test "$(cat "$local_success")" -ge "$(cat "$timestamp")"
            ''}
            age=$(($(date +%s) - $(cat "$timestamp")))
            test "$age" -lt 86400
          '';
        };
      };

    systemd.services."restic-backups-${localJob}" = lib.mkIf cfg.local.enable {
      unitConfig = {
        RequiresMountsFor = [cfg.local.mountPoint];
        ConditionPathIsMountPoint = cfg.local.mountPoint;
        OnSuccess = ["backup-success-${localJob}.service"];
      };
    };
    systemd.services."backup-success-${localJob}" = lib.mkIf cfg.local.enable (mkSuccessMetricService localJob);

    systemd.services."restic-backups-${offsiteJob}" = lib.mkIf cfg.offsite.enable {
      after = lib.optional cfg.local.enable "restic-backups-${localJob}.service";
      unitConfig.OnSuccess = ["backup-success-${offsiteJob}.service"];
    };
    systemd.services."backup-success-${offsiteJob}" = lib.mkIf cfg.offsite.enable (mkSuccessMetricService offsiteJob);

    # Weekly repository metadata/data sampling. Full restore validation runs monthly.
    systemd.services.homeassistant-backup-check = lib.mkIf cfg.local.enable {
      description = "Check local Home Assistant Restic repository";
      serviceConfig.Type = "oneshot";
      unitConfig = {
        RequiresMountsFor = [cfg.local.mountPoint];
        ConditionPathIsMountPoint = cfg.local.mountPoint;
      };
      script = ''
        export RESTIC_REPOSITORY=${lib.escapeShellArg (toString cfg.local.repository)}
        export RESTIC_PASSWORD_FILE=${lib.escapeShellArg (toString cfg.passwordFile)}
        ${pkgs.restic}/bin/restic check --read-data-subset=5%
      '';
    };
    systemd.timers.homeassistant-backup-check = lib.mkIf cfg.local.enable {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "Sun *-*-* 06:30:00";
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };

    systemd.services.homeassistant-backup-restore-test = lib.mkIf cfg.local.enable {
      description = "Restore-test latest Home Assistant backup";
      serviceConfig.Type = "oneshot";
      unitConfig = {
        RequiresMountsFor = [cfg.local.mountPoint];
        ConditionPathIsMountPoint = cfg.local.mountPoint;
      };
      script = ''
        set -euo pipefail
        target=$(${pkgs.coreutils}/bin/mktemp -d /var/tmp/homeassistant-restore-test.XXXXXX)
        trap '${pkgs.coreutils}/bin/rm -rf "$target"' EXIT
        export RESTIC_REPOSITORY=${lib.escapeShellArg (toString cfg.local.repository)}
        export RESTIC_PASSWORD_FILE=${lib.escapeShellArg (toString cfg.passwordFile)}
        ${pkgs.restic}/bin/restic restore latest --target "$target"
        restored="$target${stagingDir}/homeassistant"
        test -s "$restored/.storage/core.config"
        db="$restored/home-assistant_v2.db"
        if [ -f "$db" ]; then
          result="$(${pkgs.sqlite}/bin/sqlite3 "$db" 'PRAGMA integrity_check;')"
          test "$result" = ok
        fi
      '';
    };
    systemd.timers.homeassistant-backup-restore-test = lib.mkIf cfg.local.enable {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "monthly";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
