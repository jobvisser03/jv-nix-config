{config, ...}: {
  sops = {
    defaultSopsFile = ../../secrets/mac-intel-nixos.yaml;
    secrets = {
      rclone_config = {
        owner = "root";
        group = "root";
        mode = "0400";
        path = "/run/secrets/rclone.conf";
      };
    };
  };
}
