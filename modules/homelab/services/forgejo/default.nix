# Forgejo - A painless, self-hosted Git service
# Based on: https://git.notthebe.ee/notthebee/nix-config/src/branch/main/modules/homelab/services/forgejo/default.nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.forgejo;
  homelab = config.homelab;
in {
  options.homelab.services.forgejo = {
    enable = lib.mkEnableOption "Forgejo - A painless, self-hosted Git service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "HTTP port for the Forgejo web interface";
    };

    # Homepage dashboard integration
    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Forgejo";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "A painless, self-hosted Git service";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "forgejo.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Accept GIT_PROTOCOL environment variable over SSH for protocol v2 support
    services.openssh.settings.AcceptEnv = "GIT_PROTOCOL";

    services.forgejo = {
      enable = true;
      database.type = "postgres";
      lfs.enable = true;
      settings = {
        server = {
          DOMAIN =
            if homelab.domain != null
            then "git.${homelab.domain}"
            else homelab.hostname;
          ROOT_URL =
            if homelab.domain != null
            then "https://git.${homelab.domain}/"
            else "http://${homelab.hostname}:${toString cfg.port}/";
          HTTP_PORT = cfg.port;
          SSH_PORT = lib.head config.services.openssh.ports;
        };
        log = {
          LEVEL = "Trace";
        };
        service = {
          DISABLE_REGISTRATION = true;
        };
      };
    };

    # Caddy reverse proxy
    services.caddy.virtualHosts = lib.mkIf homelab.services.enableReverseProxy (
      {
        # Internal HTTP access via hostname:port (LAN/Tailscale)
        "http://${homelab.hostname}:${toString cfg.port}" = {
          extraConfig = ''
            reverse_proxy http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}
            request_body {
              max_size 10GB
            }
          '';
        };
      }
      // (lib.optionalAttrs (homelab.domain != null) {
        # Public HTTPS vhost for git.<domain>
        "git.${homelab.domain}" = {
          extraConfig = ''
            reverse_proxy http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}
            request_body {
              max_size 10GB
            }
          '';
        };
      })
    );

    # Open firewall for Forgejo access on local network
    networking.firewall.allowedTCPPorts = [cfg.port];
  };
}
