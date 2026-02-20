# Paperless-ngx - Self-hosted document management system
{
  config,
  lib,
  ...
}: let
  service = "paperless";
  cfg = config.homelab.services.${service};
  homelab = config.homelab;
in {
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption "Paperless-ngx - Self-hosted document management system";

    port = lib.mkOption {
      type = lib.types.port;
      default = 28981;
      description = "Port for Paperless-ngx web interface";
    };

    mediaDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/usb-drive/PAPERLESS/Documents";
      description = "Path to store processed documents";
    };

    consumptionDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/usb-drive/PAPERLESS/Import";
      description = "Path where documents are placed for automatic import";
    };

    passwordFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing the admin password";
    };

    # Homepage dashboard integration
    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Paperless-ngx";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Document management system";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "paperless.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.paperless = {
      enable = true;
      # Use internal port when reverse proxy is enabled to avoid port conflict
      port =
        if homelab.services.enableReverseProxy
        then cfg.port + 10000
        else cfg.port;
      passwordFile = cfg.passwordFile;
      user = homelab.user;
      mediaDir = cfg.mediaDir;
      consumptionDir = cfg.consumptionDir;
      consumptionDirIsPublic = true;
      settings = {
        PAPERLESS_URL = "http://${homelab.hostname}:${toString cfg.port}";
        PAPERLESS_CONSUMER_IGNORE_PATTERN = [
          ".DS_STORE/*"
          "desktop.ini"
        ];
        PAPERLESS_OCR_LANGUAGE = "nld+eng";
        PAPERLESS_OCR_USER_ARGS = {
          optimize = 1;
          pdfa_image_compression = "lossless";
        };
      };
    };

    # Caddy reverse proxy (HTTP, port-based - matching homelab pattern)
    services.caddy.virtualHosts = lib.mkIf homelab.services.enableReverseProxy {
      "http://${homelab.hostname}:${toString cfg.port}" = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString (cfg.port + 10000)}
        '';
      };
    };

    # Ensure paperless directories exist with correct ownership
    # Using 'd' to create if missing, 'Z' to fix ownership recursively on existing dirs
    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir} 0755 ${homelab.user} ${homelab.group} -"
      "d ${cfg.consumptionDir} 0755 ${homelab.user} ${homelab.group} -"
      "Z ${cfg.mediaDir} 0755 ${homelab.user} ${homelab.group} -"
      "Z ${cfg.consumptionDir} 0755 ${homelab.user} ${homelab.group} -"
    ];

    # Open firewall for access
    networking.firewall.allowedTCPPorts = [cfg.port];
  };
}
