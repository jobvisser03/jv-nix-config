# Prometheus - host metrics collection
{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.services.prometheus;
  homelab = config.homelab;
  prometheusUrl = "http://127.0.0.1:${toString cfg.internalPort}";
in {
  options.homelab.services.prometheus = {
    enable = lib.mkEnableOption "Prometheus metrics collection";

    port = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = "LAN port for the Prometheus web interface";
    };

    internalPort = lib.mkOption {
      type = lib.types.port;
      default = 19090;
      description = "Loopback port used behind Caddy";
    };

    scrapeInterval = lib.mkOption {
      type = lib.types.str;
      default = "5s";
      description = "Interval between local metric scrapes";
    };

    retentionTime = lib.mkOption {
      type = lib.types.str;
      default = "30d";
      description = "Prometheus time-series retention period";
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Prometheus";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Host metrics and time series";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "prometheus.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Observability";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = cfg.internalPort;
      retentionTime = cfg.retentionTime;
      globalConfig.scrape_interval = cfg.scrapeInterval;

      exporters = {
        node = {
          enable = true;
          listenAddress = "127.0.0.1";
          openFirewall = false;
        };
        systemd = {
          enable = true;
          listenAddress = "127.0.0.1";
          openFirewall = false;
        };
        smartctl = {
          enable = true;
          listenAddress = "127.0.0.1";
          openFirewall = false;
        };
      };

      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [{targets = ["127.0.0.1:${toString config.services.prometheus.exporters.node.port}"];}];
        }
        {
          job_name = "systemd";
          static_configs = [{targets = ["127.0.0.1:${toString config.services.prometheus.exporters.systemd.port}"];}];
        }
        {
          job_name = "smartctl";
          static_configs = [{targets = ["127.0.0.1:${toString config.services.prometheus.exporters.smartctl.port}"];}];
        }
      ];
    };

    services.grafana.provision = lib.mkIf config.homelab.services.grafana.enable {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = prometheusUrl;
            isDefault = true;
            editable = false;
          }
        ];
      };
    };

    services.caddy.virtualHosts = lib.mkIf homelab.services.enableReverseProxy {
      "http://${homelab.hostname}:${toString cfg.port}" = {
        extraConfig = ''
          reverse_proxy ${prometheusUrl}
        '';
      };
    };
  };
}
