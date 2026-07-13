# Uptime Kuma - intended for a future external monitoring VPS
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.uptime-kuma;
  homelab = config.homelab;
in {
  options.homelab.services.uptime-kuma = {
    enable = lib.mkEnableOption "Uptime Kuma monitoring server";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3001;
      description = "HTTP port for the Uptime Kuma web interface";
    };

    internalPort = lib.mkOption {
      type = lib.types.port;
      default = 13001;
      description = "Loopback port used behind Caddy";
    };

    publicHost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "uptime.example.com";
      description = "Optional public hostname for an external Uptime Kuma server";
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Uptime Kuma";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "External uptime monitoring";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "uptime-kuma.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Observability";
      };
    };

    heartbeat = {
      enable = lib.mkEnableOption "push heartbeat to an external Uptime Kuma monitor";

      pushUrlFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "File containing the secret Uptime Kuma push-monitor URL";
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "30s";
        description = "Interval between external heartbeat pushes";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.uptime-kuma = {
        enable = true;
        settings = {
          HOST = "127.0.0.1";
          PORT = toString cfg.internalPort;
        };
      };

      services.caddy.virtualHosts = lib.mkIf homelab.services.enableReverseProxy (
        {
          "http://${homelab.hostname}:${toString cfg.port}" = {
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString cfg.internalPort}
            '';
          };
        }
        // lib.optionalAttrs (cfg.publicHost != null) {
          "${cfg.publicHost}" = {
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString cfg.internalPort}
            '';
          };
        }
      );
    })

    (lib.mkIf cfg.heartbeat.enable {
      assertions = [
        {
          assertion = cfg.heartbeat.pushUrlFile != null;
          message = "homelab.services.uptime-kuma.heartbeat.pushUrlFile must be set when heartbeat is enabled";
        }
      ];

      systemd.services.uptime-kuma-heartbeat = {
        description = "Push heartbeat to external Uptime Kuma";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        serviceConfig = {
          Type = "oneshot";
          LoadCredential = "push-url:${toString cfg.heartbeat.pushUrlFile}";
        };
        script = ''
          url="$(${pkgs.coreutils}/bin/tr -d '\n' < "$CREDENTIALS_DIRECTORY/push-url")"
          ${pkgs.curl}/bin/curl --fail --silent --show-error --max-time 10 "$url"
        '';
      };

      systemd.timers.uptime-kuma-heartbeat = {
        description = "Schedule external Uptime Kuma heartbeat";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = cfg.heartbeat.interval;
          Unit = "uptime-kuma-heartbeat.service";
        };
      };
    })
  ];
}
