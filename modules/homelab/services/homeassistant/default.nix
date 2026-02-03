# Home Assistant - Home automation platform (OCI container)
{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.services.homeassistant;
  homelab = config.homelab;
in {
  options.homelab.services.homeassistant = {
    enable = lib.mkEnableOption "Home Assistant - Home automation platform";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8123;
      description = "Port for Home Assistant web interface";
    };

    configDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/homeassistant";
      description = "Path to store Home Assistant configuration";
    };

    image = lib.mkOption {
      type = lib.types.str;
      default = "homeassistant/home-assistant:stable";
      description = "Docker image for Home Assistant";
    };

    # Homepage dashboard integration
    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Home Assistant";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Home automation platform";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "home-assistant.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Smart Home";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Create config directory
    systemd.tmpfiles.rules = [
      "d ${cfg.configDir} 0775 ${homelab.user} ${homelab.group} - -"
    ];

    # Home Assistant OCI container
    virtualisation.oci-containers.containers.homeassistant = {
      image = cfg.image;
      autoStart = true;

      # Pull newer image on restart
      extraOptions = [
        "--pull=newer"
      ];

      volumes = [
        "${cfg.configDir}:/config"
      ];

      ports =
        if homelab.services.enableReverseProxy
        then ["127.0.0.1:${toString cfg.port}:8123"]
        else ["${toString cfg.port}:8123"]; # Bind to all interfaces

      environment = {
        TZ = homelab.timeZone;
      };
    };

    # Caddy reverse proxy
    services.caddy.virtualHosts = lib.mkIf homelab.services.enableReverseProxy {
      "http://${homelab.hostname}:${toString cfg.port}" = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString cfg.port}
        '';
      };
    };

    # Open firewall for Home Assistant
    networking.firewall.allowedTCPPorts = [cfg.port];
  };
}
