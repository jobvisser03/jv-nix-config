# Home Assistant - Home automation platform with Zigbee2MQTT and Mosquitto
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
      default = "ghcr.io/home-assistant/home-assistant:stable";
      description = "Docker image for Home Assistant";
    };

    # Zigbee2MQTT options
    zigbee2mqtt = {
      enable = lib.mkEnableOption "Zigbee2MQTT for Zigbee device support";

      image = lib.mkOption {
        type = lib.types.str;
        default = "koenkk/zigbee2mqtt:latest";
        description = "Docker image for Zigbee2MQTT";
      };

      configDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/zigbee2mqtt";
        description = "Path to store Zigbee2MQTT configuration";
      };

      usbDevice = lib.mkOption {
        type = lib.types.str;
        default = "/dev/ttyUSB0";
        description = "Path to the Zigbee USB adapter (use /dev/serial/by-id/... for stability)";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "Port for Zigbee2MQTT web interface";
      };
    };

    # Mosquitto MQTT broker options
    mosquitto = {
      enable = lib.mkEnableOption "Mosquitto MQTT broker";

      image = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/library/eclipse-mosquitto:1.6.9";
        description = "Docker image for Mosquitto MQTT broker";
      };

      configDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/mosquitto";
        description = "Path to store Mosquitto configuration";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 1883;
        description = "Port for MQTT broker";
      };

      websocketPort = lib.mkOption {
        type = lib.types.port;
        default = 9001;
        description = "Port for MQTT WebSocket connections";
      };
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
    # Create config directories
    systemd.tmpfiles.rules =
      [
        "d ${cfg.configDir} 0775 ${homelab.user} ${homelab.group} - -"
      ]
      ++ lib.optionals cfg.zigbee2mqtt.enable [
        "d ${cfg.zigbee2mqtt.configDir} 0775 ${homelab.user} ${homelab.group} - -"
      ]
      ++ lib.optionals cfg.mosquitto.enable [
        "d ${cfg.mosquitto.configDir} 0775 ${homelab.user} ${homelab.group} - -"
        "d ${cfg.mosquitto.configDir}/config 0775 ${homelab.user} ${homelab.group} - -"
        "d ${cfg.mosquitto.configDir}/data 0775 ${homelab.user} ${homelab.group} - -"
        "d ${cfg.mosquitto.configDir}/log 0775 ${homelab.user} ${homelab.group} - -"
      ];

    # Udev rules for Zigbee USB adapter (Sonoff Zigbee 3.0 USB Dongle Plus)
    # This allows container access without privileged mode
    services.udev.extraRules = lib.mkIf cfg.zigbee2mqtt.enable ''
      # Sonoff Zigbee 3.0 USB Dongle Plus (CH9102 USB-Serial)
      SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55d4", MODE="0666", GROUP="dialout"
      # Alternative: Silicon Labs CP210x (some Sonoff variants)
      SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout"
    '';

    # ==========================================
    # Mosquitto MQTT Broker Container
    # ==========================================
    virtualisation.oci-containers.containers.mosquitto = lib.mkIf cfg.mosquitto.enable {
      image = cfg.mosquitto.image;
      autoStart = true;

      extraOptions = [
        "--network=host"
      ];

      volumes = [
        "${cfg.mosquitto.configDir}:/mosquitto"
      ];

      environment = {
        TZ = homelab.timeZone;
      };
    };

    # Create default Mosquitto config if it doesn't exist
    # Mosquitto 1.6.9 needs a config file to work properly
    environment.etc."mosquitto-default.conf" = lib.mkIf cfg.mosquitto.enable {
      text = ''
        # Mosquitto MQTT Broker Configuration
        listener ${toString cfg.mosquitto.port}
        listener ${toString cfg.mosquitto.websocketPort}
        protocol websockets

        # Allow anonymous connections (local network only)
        allow_anonymous true

        # Persistence
        persistence true
        persistence_location /mosquitto/data/

        # Logging
        log_dest file /mosquitto/log/mosquitto.log
        log_dest stdout
      '';
    };

    # ==========================================
    # Zigbee2MQTT Container
    # ==========================================
    virtualisation.oci-containers.containers.zigbee2mqtt = lib.mkIf cfg.zigbee2mqtt.enable {
      image = cfg.zigbee2mqtt.image;
      autoStart = true;

      extraOptions =
        [
          "--pull=newer"
          "--network=host"
          # USB device access
          "--device=${cfg.zigbee2mqtt.usbDevice}:/dev/ttyUSB0"
        ]
        # Add the by-id symlink if the device path uses it (for device stability)
        ++ lib.optionals (lib.hasPrefix "/dev/serial/by-id/" cfg.zigbee2mqtt.usbDevice) [
          "--device=${cfg.zigbee2mqtt.usbDevice}:/dev/sonoff"
        ];

      volumes = [
        "${cfg.zigbee2mqtt.configDir}:/app/data"
        "/run/udev:/run/udev:ro"
      ];

      environment = {
        TZ = homelab.timeZone;
      };

      dependsOn = lib.optionals cfg.mosquitto.enable ["mosquitto"];
    };

    # ==========================================
    # Home Assistant Container
    # ==========================================
    virtualisation.oci-containers.containers.homeassistant = {
      image = cfg.image;
      autoStart = true;

      extraOptions =
        [
          "--pull=newer"
          "--network=host"
        ]
        # Mount serial devices if Zigbee2MQTT is enabled (for device discovery)
        ++ lib.optionals cfg.zigbee2mqtt.enable [
          "--device=${cfg.zigbee2mqtt.usbDevice}:${cfg.zigbee2mqtt.usbDevice}"
        ];

      volumes =
        [
          "${cfg.configDir}:/config"
          "/etc/localtime:/etc/localtime:ro"
        ]
        # Mount serial devices directory for device discovery
        ++ lib.optionals cfg.zigbee2mqtt.enable [
          "/dev/serial/by-id:/dev/serial/by-id:ro"
        ];

      environment = {
        TZ = homelab.timeZone;
      };

      # Wait for MQTT and Zigbee2MQTT to be ready
      dependsOn =
        lib.optionals cfg.mosquitto.enable ["mosquitto"]
        ++ lib.optionals cfg.zigbee2mqtt.enable ["zigbee2mqtt"];
    };

    # ==========================================
    # Firewall Configuration
    # ==========================================
    networking.firewall.allowedTCPPorts =
      [cfg.port]
      ++ lib.optionals cfg.mosquitto.enable [
        cfg.mosquitto.port
        cfg.mosquitto.websocketPort
      ]
      ++ lib.optionals cfg.zigbee2mqtt.enable [
        cfg.zigbee2mqtt.port
      ];

    # ==========================================
    # Caddy Reverse Proxy (if enabled)
    # ==========================================
    services.caddy.virtualHosts = lib.mkIf homelab.services.enableReverseProxy {
      "http://${homelab.hostname}:${toString cfg.port}" = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString cfg.port}
        '';
      };
    };
  };
}
