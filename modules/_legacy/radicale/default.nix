# Radicale - CalDAV and CardDAV server
{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.services.radicale;
  homelab = config.homelab;
  # Internal port for Radicale (Caddy proxies external port to this)
  internalPort = cfg.port + 10000;
in {
  options.homelab.services.radicale = {
    enable = lib.mkEnableOption "Radicale - CalDAV and CardDAV server";

    port = lib.mkOption {
      type = lib.types.port;
      default = 5232;
      description = "External port for Radicale web interface (via Caddy)";
    };

    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to htpasswd file for authentication.
        Create with: htpasswd -c /etc/secrets/radicale-htpasswd username
        Format: username:password (plain text) or username:$apr1$... (htpasswd)
      '';
      example = "/etc/secrets/radicale-htpasswd";
    };

    # Homepage dashboard integration
    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Radicale";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "CalDAV/CardDAV server";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "radicale.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Load htpasswd credentials securely if provided
    systemd.services.radicale.serviceConfig = lib.mkIf (cfg.passwordFile != null) {
      LoadCredential = "radicale.htpasswd:${cfg.passwordFile}";
    };

    services.radicale = {
      enable = true;

      settings = {
        server = {
          # When reverse proxy is enabled, listen on internal port only
          # Otherwise, listen on all interfaces on the configured port
          hosts =
            if homelab.services.enableReverseProxy
            then ["127.0.0.1:${toString internalPort}"]
            else ["0.0.0.0:${toString cfg.port}"];
        };

        storage = {
          filesystem_folder = "/var/lib/radicale/collections";
        };

        auth =
          if (cfg.passwordFile != null)
          then {
            type = "htpasswd";
            htpasswd_filename = "%d/radicale.htpasswd";
            htpasswd_encryption = "plain";
          }
          else {
            # Radicale 3.5.0+ requires explicit auth.type (default changed from "none" to "denyall")
            type = "none";
          };
      };
    };

    # Caddy reverse proxy - external port to internal Radicale
    services.caddy.virtualHosts = lib.mkIf homelab.services.enableReverseProxy {
      "http://${homelab.hostname}:${toString cfg.port}" = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString internalPort}
        '';
      };
    };

    # Open firewall for CalDAV/CardDAV access on local network
    networking.firewall.allowedTCPPorts = [cfg.port];
  };
}
