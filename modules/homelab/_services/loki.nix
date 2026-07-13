# Local log storage and journal ingestion for homelab services
{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.services.loki;
  lokiUrl = "http://127.0.0.1:${toString cfg.port}";
in {
  options.homelab.services.loki = {
    enable = lib.mkEnableOption "Loki log storage with Grafana Alloy ingestion";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3100;
      description = "Loopback Loki API port";
    };

    retentionPeriod = lib.mkOption {
      type = lib.types.str;
      default = "720h";
      description = "Log retention period";
    };
  };

  config = lib.mkIf cfg.enable {
    services.loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server = {
          http_listen_address = "127.0.0.1";
          http_listen_port = cfg.port;
        };
        common = {
          path_prefix = "/var/lib/loki";
          replication_factor = 1;
          ring.kvstore.store = "inmemory";
          storage.filesystem = {
            chunks_directory = "/var/lib/loki/chunks";
            rules_directory = "/var/lib/loki/rules";
          };
        };
        schema_config.configs = [
          {
            from = "2024-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
        compactor = {
          working_directory = "/var/lib/loki/compactor";
          retention_enabled = true;
          delete_request_store = "filesystem";
        };
        limits_config = {
          retention_period = cfg.retentionPeriod;
          allow_structured_metadata = true;
        };
      };
    };

    services.alloy = {
      enable = true;
      extraFlags = ["--disable-reporting"];
    };

    environment.etc."alloy/homeassistant.alloy".text = ''
      loki.source.journal "homeassistant" {
        matches = "_SYSTEMD_UNIT=podman-homeassistant.service"
        labels = {
          host = "${config.networking.hostName}",
          service = "homeassistant",
          source = "journal",
        }
        forward_to = [loki.write.local.receiver]
      }

      loki.source.journal "zigbee2mqtt" {
        matches = "_SYSTEMD_UNIT=podman-zigbee2mqtt.service"
        labels = {
          host = "${config.networking.hostName}",
          service = "zigbee2mqtt",
          source = "journal",
        }
        forward_to = [loki.write.local.receiver]
      }

      loki.source.journal "mosquitto" {
        matches = "_SYSTEMD_UNIT=podman-mosquitto.service"
        labels = {
          host = "${config.networking.hostName}",
          service = "mosquitto",
          source = "journal",
        }
        forward_to = [loki.write.local.receiver]
      }

      loki.write "local" {
        endpoint {
          url = "${lokiUrl}/loki/api/v1/push"
        }
      }
    '';

    services.grafana.provision = lib.mkIf config.homelab.services.grafana.enable {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Loki";
          uid = "loki";
          type = "loki";
          url = lokiUrl;
          editable = false;
        }
      ];
    };

    # NixOS defaults to persistent journals; cap local journal disk use explicitly.
    services.journald = {
      storage = "persistent";
      extraConfig = ''
        SystemMaxUse=1G
        MaxRetentionSec=14day
      '';
    };
  };
}
