# Grafana - metrics dashboards
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.grafana;
  homelab = config.homelab;
  dashboards = pkgs.runCommand "homelab-grafana-dashboards" {} ''
    mkdir -p $out
    cp ${../_dashboards/homeassistant-observability.json} $out/homeassistant-observability.json
  '';
in {
  options.homelab.services.grafana = {
    enable = lib.mkEnableOption "Grafana metrics dashboards";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3002;
      description = "LAN port for the Grafana web interface";
    };

    internalPort = lib.mkOption {
      type = lib.types.port;
      default = 13002;
      description = "Loopback port used behind Caddy";
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Grafana";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Metrics dashboards";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "grafana.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Observability";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.grafana = {
      enable = true;
      settings = {
        security.secret_key = "$__file{${config.services.grafana.dataDir}/secret_key}";
        server = {
          http_addr = "127.0.0.1";
          http_port = cfg.internalPort;
          domain = homelab.hostname;
          root_url = "http://${homelab.hostname}:${toString cfg.port}/";
        };
      };
    };

    services.grafana.provision = {
      enable = true;
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "Homelab";
            type = "file";
            disableDeletion = true;
            editable = true;
            options.path = dashboards;
          }
        ];
      };
    };

    # Grafana 11+ requires a stable, user-provided encryption key. Generate it
    # once in Grafana's persistent state directory instead of the Nix store.
    systemd.services.grafana.preStart = lib.mkBefore ''
      if [[ ! -s ${config.services.grafana.dataDir}/secret_key ]]; then
        umask 077
        ${pkgs.openssl}/bin/openssl rand -hex 32 > ${config.services.grafana.dataDir}/secret_key
      fi
    '';

    services.caddy.virtualHosts = lib.mkIf homelab.services.enableReverseProxy {
      "http://${homelab.hostname}:${toString cfg.port}" = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString cfg.internalPort}
        '';
      };
    };

    # Caddy accepts LAN connections on Grafana's public port.
    networking.firewall.allowedTCPPorts = [cfg.port];
  };
}
