# Auto-generated using compose2nix v0.3.2-pre.
{
  pkgs,
  lib,
  ...
}: {

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    oci-containers.backend = "docker";
    # Set up resource limits
    daemon.settings = {
      experimental = true;
      default-address-pools = [
        {
          base = "172.30.0.0/16";
          size = 24;
        }
      ];
    };
  };
  # Containers
  virtualisation.oci-containers.containers."ofelia" = {
    image = "mcuadros/ofelia:latest";
    volumes = [
      "/home/job/photoprism-docker-config/jobs.ini:/etc/ofelia/config.ini:rw"
      "/var/run/docker.sock:/var/run/docker.sock:ro"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=ofelia"
      "--network=photoprism_default"
    ];
  };
  systemd.services."docker-ofelia" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-photoprism_default.service"
    ];
    requires = [
      "docker-network-photoprism_default.service"
    ];
    partOf = [
      "docker-compose-photoprism-root.target"
    ];
    wantedBy = [
      "docker-compose-photoprism-root.target"
    ];
  };
  virtualisation.oci-containers.containers."photoprism-mariadb" = {
    image = "mariadb:11";
    environment = {
      "MARIADB_AUTO_UPGRADE" = "1";
      "MARIADB_DATABASE" = "photoprism";
      "MARIADB_INITDB_SKIP_TZINFO" = "1";
      "MARIADB_PASSWORD" = "insecure";
      "MARIADB_ROOT_PASSWORD" = "insecure";
      "MARIADB_USER" = "photoprism";
    };
    volumes = [
      "/home/job/photoprism-docker-config/database:/var/lib/mysql:rw"
    ];
    cmd = ["--innodb-buffer-pool-size=1G" "--transaction-isolation=READ-COMMITTED" "--character-set-server=utf8mb4" "--collation-server=utf8mb4_unicode_ci" "--max-connections=512" "--innodb-rollback-on-timeout=OFF" "--innodb-lock-wait-timeout=120"];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=mariadb"
      "--network=photoprism_default"
      "--security-opt=apparmor:unconfined"
      "--security-opt=seccomp:unconfined"
    ];
  };
  systemd.services."docker-photoprism-mariadb" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-photoprism_default.service"
    ];
    requires = [
      "docker-network-photoprism_default.service"
    ];
    partOf = [
      "docker-compose-photoprism-root.target"
    ];
    wantedBy = [
      "docker-compose-photoprism-root.target"
    ];
  };
  virtualisation.oci-containers.containers."photoprism-photoprism" = {
    image = "photoprism/photoprism:latest";
    environment = {
      "PHOTOPRISM_ADMIN_PASSWORD" = "password";
      "PHOTOPRISM_ADMIN_USER" = "admin";
      "PHOTOPRISM_AUTH_MODE" = "password";
      "PHOTOPRISM_DATABASE_DRIVER" = "mysql";
      "PHOTOPRISM_DATABASE_NAME" = "photoprism";
      "PHOTOPRISM_DATABASE_PASSWORD" = "insecure";
      "PHOTOPRISM_DATABASE_SERVER" = "mariadb:3306";
      "PHOTOPRISM_DATABASE_USER" = "photoprism";
      "PHOTOPRISM_DEFAULT_TLS" = "true";
      "PHOTOPRISM_DETECT_NSFW" = "false";
      "PHOTOPRISM_DISABLE_CHOWN" = "false";
      "PHOTOPRISM_DISABLE_CLASSIFICATION" = "false";
      "PHOTOPRISM_DISABLE_FACES" = "false";
      "PHOTOPRISM_DISABLE_RAW" = "false";
      "PHOTOPRISM_DISABLE_SETTINGS" = "false";
      "PHOTOPRISM_DISABLE_TENSORFLOW" = "false";
      "PHOTOPRISM_DISABLE_TLS" = "false";
      "PHOTOPRISM_DISABLE_VECTORS" = "false";
      "PHOTOPRISM_DISABLE_WEBDAV" = "false";
      "PHOTOPRISM_EXPERIMENTAL" = "false";
      "PHOTOPRISM_HTTP_COMPRESSION" = "gzip";
      "PHOTOPRISM_JPEG_QUALITY" = "85";
      "PHOTOPRISM_LOG_LEVEL" = "info";
      "PHOTOPRISM_ORIGINALS_LIMIT" = "5000";
      "PHOTOPRISM_RAW_PRESETS" = "false";
      "PHOTOPRISM_READONLY" = "false";
      "PHOTOPRISM_SITE_AUTHOR" = "";
      "PHOTOPRISM_SITE_CAPTION" = "Photoprism";
      "PHOTOPRISM_SITE_DESCRIPTION" = "";
      "PHOTOPRISM_SITE_URL" = "http://localhost:2342/";
      "PHOTOPRISM_UPLOAD_NSFW" = "true";
      "PHOTOPRISM_WORKERS" = "4";
    };
    volumes = [
      "/home/job/photoprism-docker-config/storage:/photoprism/storage:rw"
      "/media/usb-drive/PICTURES:/photoprism/originals:rw"
    ];
    ports = [
      "2342:2342/tcp"
    ];
    dependsOn = [
      "photoprism-mariadb"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=photoprism"
      "--network=photoprism_default"
      "--security-opt=apparmor:unconfined"
      "--security-opt=seccomp:unconfined"
    ];
  };
  systemd.services."docker-photoprism-photoprism" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-photoprism_default.service"
    ];
    requires = [
      "docker-network-photoprism_default.service"
    ];
    partOf = [
      "docker-compose-photoprism-root.target"
    ];
    wantedBy = [
      "docker-compose-photoprism-root.target"
    ];
  };

  # Networks
  systemd.services."docker-network-photoprism_default" = {
    path = [pkgs.docker];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f photoprism_default";
    };
    script = ''
      docker network inspect photoprism_default || docker network create photoprism_default
    '';
    partOf = ["docker-compose-photoprism-root.target"];
    wantedBy = ["docker-compose-photoprism-root.target"];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-compose-photoprism-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = ["multi-user.target"];
  };
}
