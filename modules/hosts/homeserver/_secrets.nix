# Homeserver secrets configuration.
#
# Decryption requires this host's ssh-to-age recipient in .sops.yaml and
# `sops updatekeys secrets/shared.yaml` (see docs/homeserver.md). Until then
# activation warns and the pCloud timers fail; the rest of the system works.
{...}: {
  sops.secrets = {
    # Rclone configuration file (contains pCloud OAuth token)
    rclone_config = {
      sopsFile = ../../../secrets/shared.yaml;
      owner = "root";
      group = "root";
      mode = "0400";
      path = "/run/secrets/rclone.conf";
    };
  };
}
