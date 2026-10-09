# pCloud integration, all via rclone CLI (no FUSE mounts on this host):
#   - pull: pCloud is the source of truth for camera photos; mirror them
#     nightly into tank/photos before Immich's 02:00 library scan.
#   - push: back up non-photo datasets to pCloud. Photos are not pushed back.
{
  config,
  pkgs,
  ...
}: let
  rclone = "${pkgs.rclone}/bin/rclone --config ${config.sops.secrets.rclone_config.path}";
  backupRoot = "pcloud:HOMESERVER-BACKUP";
in {
  systemd.services.pcloud-photos-pull = {
    description = "Mirror pCloud camera photos into tank/photos";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    unitConfig.RequiresMountsFor = ["/tank/photos"];
    serviceConfig = {
      Type = "oneshot";
      Nice = 10;
      IOSchedulingClass = "idle";
    };
    # --max-delete guards against a pCloud glitch wiping the mirror;
    # sanoid snapshots on tank/photos cover anything that slips through.
    script = ''
      ${rclone} sync "pcloud:PHOTOS" /tank/photos/PHOTOS-PCLOUD --max-delete 500
      ${rclone} sync "pcloud:Automatic Upload" /tank/photos/SMARTPHONE-PHOTOS-PCLOUD --max-delete 500
    '';
  };
  systemd.timers.pcloud-photos-pull = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 01:00:00";
      Persistent = true;
    };
  };

  # Changed/deleted files are moved to a dated .versions folder instead of lost.
  systemd.services.pcloud-backup = {
    description = "Back up tank datasets to pCloud";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    unitConfig.RequiresMountsFor = [
      "/tank/documents"
      "/tank/backups"
      "/tank/immich"
    ];
    serviceConfig = {
      Type = "oneshot";
      Nice = 10;
      IOSchedulingClass = "idle";
    };
    script = ''
      versions="${backupRoot}/.versions/$(date +%F)"
      ${rclone} sync /tank/documents "${backupRoot}/documents" --backup-dir "$versions/documents"
      ${rclone} sync /tank/backups "${backupRoot}/backups" --backup-dir "$versions/backups"
      # Immich originals and DB dumps only; thumbs and transcodes are regenerable.
      ${rclone} sync /tank/immich "${backupRoot}/immich" --backup-dir "$versions/immich" \
        --exclude '/thumbs/**' --exclude '/encoded-video/**'
    '';
  };
  systemd.timers.pcloud-backup = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00";
      Persistent = true;
    };
  };
}
