# Home Assistant - Home automation platform with Zigbee2MQTT and Mosquitto
{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.services.homeassistant;
  homelab = config.homelab;

  # Network name for inter-container communication
  homelabNetwork = "homelab";
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
        default = "docker.io/library/eclipse-mosquitto:2";
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

    # ==========================================
    # Mosquitto Configuration Setup
    # ==========================================
    # Deploy Mosquitto config before container starts
    systemd.services.mosquitto-setup-config = lib.mkIf cfg.mosquitto.enable {
      description = "Setup Mosquitto MQTT broker configuration";
      before = ["podman-mosquitto.service"];
      after = ["podman-homelab-network.service"];
      requires = ["podman-homelab-network.service"];
      wantedBy = ["podman-mosquitto.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };
      script = ''
                CONFIG_FILE="${cfg.mosquitto.configDir}/config/mosquitto.conf"

                # Create Mosquitto config
                cat > "$CONFIG_FILE" << 'MQTTCONFIG'
        # Mosquitto MQTT Broker Configuration - managed by NixOS
        # Listen on all interfaces for container networking
        listener ${toString cfg.mosquitto.port} 0.0.0.0

        # WebSocket listener
        listener ${toString cfg.mosquitto.websocketPort} 0.0.0.0
        protocol websockets

        # Allow anonymous connections (local network only)
        allow_anonymous true

        # Persistence
        persistence true
        persistence_location /mosquitto/data/

        # Logging
        log_dest file /mosquitto/log/mosquitto.log
        log_dest stdout
        MQTTCONFIG

                # Ensure proper permissions
                chown ${homelab.user}:${homelab.group} "$CONFIG_FILE"
                chmod 644 "$CONFIG_FILE"
                echo "Mosquitto config deployed to $CONFIG_FILE"
      '';
    };

    # ==========================================
    # Home Assistant Reverse Proxy Setup
    # ==========================================
    systemd.services.homeassistant-setup-reverse-proxy = lib.mkIf homelab.services.enableReverseProxy {
      description = "Setup Home Assistant reverse proxy configuration";
      before = ["podman-homeassistant.service"];
      after = ["podman-homelab-network.service"];
      requires = ["podman-homelab-network.service"];
      wantedBy = ["podman-homeassistant.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };
      script = ''
                CONFIG_FILE="${cfg.configDir}/configuration.yaml"
                REVERSE_PROXY_CONFIG="${cfg.configDir}/reverse_proxy.yaml"
                REVERSE_PROXY_MARKER="# Reverse proxy configuration - managed by NixOS"
                INCLUDE_LINE="http: !include reverse_proxy.yaml"

                # Copy the reverse proxy configuration file
                # Note: This file is included via "http: !include reverse_proxy.yaml"
                # so it should contain the CONTENTS of the http section, not the http: key itself
                cat > "$REVERSE_PROXY_CONFIG" << 'PROXYCONFIG'
        # Reverse proxy configuration - managed by NixOS
        use_x_forwarded_for: true
        trusted_proxies:
          - 10.88.0.0/16
          - 10.89.0.0/16
          - 127.0.0.1
          - ::1
        PROXYCONFIG

                # Ensure proper permissions
                chown ${homelab.user}:${homelab.group} "$REVERSE_PROXY_CONFIG"
                chmod 644 "$REVERSE_PROXY_CONFIG"

                # Check if configuration.yaml exists
                if [ ! -f "$CONFIG_FILE" ]; then
                  # Create new configuration.yaml with default config and include
                  echo "default_config:" > "$CONFIG_FILE"
                  echo "" >> "$CONFIG_FILE"
                  echo "$REVERSE_PROXY_MARKER" >> "$CONFIG_FILE"
                  echo "$INCLUDE_LINE" >> "$CONFIG_FILE"
                  echo "Created new configuration.yaml with reverse proxy include"
                elif ! grep -q "reverse_proxy.yaml" "$CONFIG_FILE" 2>/dev/null; then
                  # Check if http section already exists
                  if grep -q "^http:" "$CONFIG_FILE" 2>/dev/null; then
                    # Backup original
                    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%s)"
                    # Remove existing http section and replace with include
                    sed -i '/^http:/,/^[^ ]/ { /^http:/d; /^[^ ]/!d; }' "$CONFIG_FILE"
                    # Add the include
                    echo "" >> "$CONFIG_FILE"
                    echo "$REVERSE_PROXY_MARKER" >> "$CONFIG_FILE"
                    echo "$INCLUDE_LINE" >> "$CONFIG_FILE"
                    echo "Replaced http section with reverse proxy include in configuration.yaml"
                  else
                    # Just append the include
                    echo "" >> "$CONFIG_FILE"
                    echo "$REVERSE_PROXY_MARKER" >> "$CONFIG_FILE"
                    echo "$INCLUDE_LINE" >> "$CONFIG_FILE"
                    echo "Added reverse proxy include to configuration.yaml"
                  fi
                else
                  echo "Reverse proxy include already present in configuration.yaml"
                fi

                # Ensure proper permissions on configuration.yaml
                chown ${homelab.user}:${homelab.group} "$CONFIG_FILE"
                chmod 644 "$CONFIG_FILE"
      '';
    };

    # Udev rules for Zigbee USB adapter (Sonoff Zigbee 3.0 USB Dongle Plus)
    # This allows container access without privileged mode
    services.udev.extraRules = lib.mkIf cfg.zigbee2mqtt.enable ''
      # Sonoff Zigbee 3.0 USB Dongle Plus (CH9102 USB-Serial)
      ACTION=="add", SUBSYSTEM=="tty", KERNEL=="ttyUSB*", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55d4", MODE="0666", GROUP="dialout", SYMLINK+="zigbee"
      # Silicon Labs CP210x (Sonoff Zigbee 3.0 USB Dongle Plus V2 and some variants)
      ACTION=="add", SUBSYSTEM=="tty", KERNEL=="ttyUSB*", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout", SYMLINK+="zigbee"
      # Also handle ttyACM devices (some adapters use CDC-ACM driver)
      ACTION=="add", SUBSYSTEM=="tty", KERNEL=="ttyACM*", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout", SYMLINK+="zigbee"
    '';

    # ==========================================
    # Mosquitto MQTT Broker Container
    # ==========================================
    virtualisation.oci-containers.containers.mosquitto = lib.mkIf cfg.mosquitto.enable {
      image = cfg.mosquitto.image;
      autoStart = true;

      extraOptions = [
        "--network=${homelabNetwork}"
        "--hostname=mosquitto"
      ];

      # Expose ports on host for external access
      ports = [
        "${toString cfg.mosquitto.port}:${toString cfg.mosquitto.port}"
        "${toString cfg.mosquitto.websocketPort}:${toString cfg.mosquitto.websocketPort}"
      ];

      volumes = [
        "${cfg.mosquitto.configDir}/config:/mosquitto/config"
        "${cfg.mosquitto.configDir}/data:/mosquitto/data"
        "${cfg.mosquitto.configDir}/log:/mosquitto/log"
      ];

      environment = {
        TZ = homelab.timeZone;
      };
    };

    # Ensure mosquitto container starts after network and config are ready
    systemd.services.podman-mosquitto = lib.mkIf cfg.mosquitto.enable {
      after = ["podman-homelab-network.service" "mosquitto-setup-config.service"];
      requires = ["podman-homelab-network.service" "mosquitto-setup-config.service"];
    };

    # ==========================================
    # Zigbee2MQTT Configuration Setup
    # ==========================================
    # Ensure Zigbee2MQTT uses the correct MQTT broker address for container networking
    systemd.services.zigbee2mqtt-setup-config = lib.mkIf cfg.zigbee2mqtt.enable {
      description = "Setup Zigbee2MQTT MQTT broker configuration";
      before = ["podman-zigbee2mqtt.service"];
      after = ["podman-homelab-network.service"];
      requires = ["podman-homelab-network.service"];
      wantedBy = ["podman-zigbee2mqtt.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };
      script = ''
        CONFIG_FILE="${cfg.zigbee2mqtt.configDir}/configuration.yaml"
        MQTT_SERVER="mqtt://mosquitto:${toString cfg.mosquitto.port}"

        if [ -f "$CONFIG_FILE" ]; then
          # Update MQTT server address if it's set to localhost
          if grep -q "server: mqtt://localhost" "$CONFIG_FILE" 2>/dev/null; then
            sed -i "s|server: mqtt://localhost:[0-9]*|server: $MQTT_SERVER|g" "$CONFIG_FILE"
            echo "Updated Zigbee2MQTT MQTT server to $MQTT_SERVER"
          elif grep -q "server: mqtt://mosquitto" "$CONFIG_FILE" 2>/dev/null; then
            echo "Zigbee2MQTT MQTT server already configured correctly"
          else
            echo "Warning: Could not find MQTT server config in $CONFIG_FILE"
          fi
        else
          echo "Zigbee2MQTT config file not found at $CONFIG_FILE - it will be created on first run"
        fi

        # Ensure proper permissions
        if [ -f "$CONFIG_FILE" ]; then
          chown ${homelab.user}:${homelab.group} "$CONFIG_FILE"
          chmod 644 "$CONFIG_FILE"
        fi
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
          "--network=${homelabNetwork}"
          "--hostname=zigbee2mqtt"
          # USB device access
          "--device=${cfg.zigbee2mqtt.usbDevice}:/dev/ttyUSB0"
        ]
        # Add the by-id symlink if the device path uses it (for device stability)
        ++ lib.optionals (lib.hasPrefix "/dev/serial/by-id/" cfg.zigbee2mqtt.usbDevice) [
          "--device=${cfg.zigbee2mqtt.usbDevice}:/dev/sonoff"
        ];

      # Expose web UI on host
      ports = [
        "${toString cfg.zigbee2mqtt.port}:8080"
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

    # Ensure zigbee2mqtt container starts after network and config are ready
    systemd.services.podman-zigbee2mqtt = lib.mkIf cfg.zigbee2mqtt.enable {
      after = ["podman-homelab-network.service" "zigbee2mqtt-setup-config.service"];
      requires = ["podman-homelab-network.service" "zigbee2mqtt-setup-config.service"];
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
          "--network=${homelabNetwork}"
          "--hostname=homeassistant"
        ]
        # Mount serial devices if Zigbee2MQTT is enabled (for device discovery)
        ++ lib.optionals cfg.zigbee2mqtt.enable [
          "--device=${cfg.zigbee2mqtt.usbDevice}:${cfg.zigbee2mqtt.usbDevice}"
        ];

      # Expose Home Assistant on localhost for Caddy reverse proxy
      # Use port+10000 internally to avoid conflict with Caddy listening on the public port
      ports =
        if homelab.services.enableReverseProxy
        then ["127.0.0.1:${toString (cfg.port + 10000)}:8123"]
        else ["${toString cfg.port}:8123"];

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

      # Note: We use systemd After= instead of dependsOn to avoid cascading failures
      # Home Assistant should start after MQTT/Zigbee2MQTT but shouldn't stop if they fail
    };

    # Ensure homeassistant container starts after network and MQTT services
    # Using After= without Requires= allows HA to keep running if other services fail
    systemd.services.podman-homeassistant = {
      after =
        ["podman-homelab-network.service"]
        ++ lib.optionals cfg.mosquitto.enable ["podman-mosquitto.service"]
        ++ lib.optionals cfg.zigbee2mqtt.enable ["podman-zigbee2mqtt.service"];
      requires = ["podman-homelab-network.service"];
      # Use Wants instead of Requires for MQTT services - HA can run without them
      wants =
        lib.optionals cfg.mosquitto.enable ["podman-mosquitto.service"]
        ++ lib.optionals cfg.zigbee2mqtt.enable ["podman-zigbee2mqtt.service"];
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
          reverse_proxy http://127.0.0.1:${toString (cfg.port + 10000)} {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };
    };
  };
}
