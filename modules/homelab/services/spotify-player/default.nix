# spotify-player - Spotify Connect daemon for homelab
# Provides a headless Spotify Connect speaker using spotify-player in daemon mode
{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.homelab.services.spotify-player;
  homelab = config.homelab;

  # Generate app.toml configuration
  appConfig = pkgs.writeText "spotify-player-app.toml" ''
    # Daemon mode settings
    enable_streaming = "Always"
    enable_media_control = false
    enable_notify = false
    client_port = ${toString cfg.port}

    [device]
    name = "${cfg.deviceName}"
    device_type = "speaker"
    volume = ${toString cfg.volume}
    bitrate = ${toString cfg.bitrate}
    audio_cache = ${lib.boolToString cfg.audioCache}
    normalization = ${lib.boolToString cfg.normalization}
    autoplay = false
  '';
in {
  options.homelab.services.spotify-player = {
    enable = lib.mkEnableOption "spotify-player - Spotify Connect daemon";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for spotify-player CLI commands";
    };

    deviceName = lib.mkOption {
      type = lib.types.str;
      default = "larkbox-spotify";
      description = "Name shown in Spotify Connect device list";
    };

    volume = lib.mkOption {
      type = lib.types.int;
      default = 70;
      description = "Initial volume percentage (0-100)";
    };

    bitrate = lib.mkOption {
      type = lib.types.enum [96 160 320];
      default = 320;
      description = "Audio bitrate in kbps";
    };

    audioCache = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Cache audio files for faster playback of repeated songs";
    };

    normalization = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable audio normalization";
    };

    credentialsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to Spotify credentials JSON file (from SOPS).
        If null, you must run `spotify_player authenticate` manually first.
      '';
    };

    # Homepage dashboard integration
    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Spotify";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Spotify Connect speaker (${cfg.deviceName})";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "spotify.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Media";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Install spotify-player package
    environment.systemPackages = [pkgs.spotify-player];

    # Enable PipeWire for audio (minimal headless config)
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      # No pulse/jack needed for headless speaker
    };
    # Ensure PulseAudio is disabled (PipeWire takes over)
    services.pulseaudio.enable = false;
    # Required for real-time audio
    security.rtkit.enable = true;

    # Create config directory and link config file
    systemd.tmpfiles.rules = [
      # Create config directory for the user running the service
      "d /home/${username}/.config/spotify-player 0755 ${username} users - -"
      # Link the generated config
      "L+ /home/${username}/.config/spotify-player/app.toml - - - - ${appConfig}"
    ];

    # Systemd user service for spotify-player daemon
    systemd.services.spotify-player = {
      description = "Spotify Player Daemon";
      after = ["network-online.target" "pipewire.service"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = username;
        Group = "users";
        ExecStart = "${pkgs.spotify-player}/bin/spotify_player -d";
        Restart = "always";
        RestartSec = 10;

        # Environment
        Environment = [
          "HOME=/home/${username}"
          "XDG_CONFIG_HOME=/home/${username}/.config"
          "XDG_CACHE_HOME=/home/${username}/.cache"
          "XDG_RUNTIME_DIR=/run/user/1000"
        ];

        # Hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = [
          "/home/${username}/.cache/spotify-player"
          "/home/${username}/.config/spotify-player"
        ];
        PrivateTmp = true;
      };

      # Copy credentials from SOPS secret if provided
      preStart = lib.mkIf (cfg.credentialsFile != null) ''
        mkdir -p /home/${username}/.cache/spotify-player
        cp ${cfg.credentialsFile} /home/${username}/.cache/spotify-player/credentials.json
        chmod 600 /home/${username}/.cache/spotify-player/credentials.json
        chown ${username}:users /home/${username}/.cache/spotify-player/credentials.json
      '';
    };

    # Add user to audio group
    users.users.${username}.extraGroups = ["audio"];

    # Avahi is already enabled on larkbox for mDNS discovery
    # Spotify Connect uses mDNS (UDP 5353) which is handled by Avahi

    # Note: No reverse proxy needed - spotify-player is controlled via
    # Spotify apps (phone/desktop) using Spotify Connect protocol,
    # not HTTP. The CLI port (8080) is only for local control.
  };
}
