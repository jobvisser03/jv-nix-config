# Jellyfin - Free Software Media System
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.jellyfin;
  homelab = config.homelab;
in {
  options.homelab.services.jellyfin = {
    enable = lib.mkEnableOption "Jellyfin - Free Software Media System";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8096;
      description = "Port for Jellyfin web interface";
    };

    mediaDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/usb-drive/MEDIA-JELLYFIN";
      description = "Path to media library (movies, TV shows, etc.)";
    };

    # Homepage dashboard integration
    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Jellyfin";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Free Software Media System";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "jellyfin.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Media";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Overlay to patch jellyfin-web with skip-intro button support
    # Requires the Intro Skipper plugin to be installed in Jellyfin
    nixpkgs.overlays = [
      (_final: prev: {
        jellyfin-web = prev.jellyfin-web.overrideAttrs (_finalAttrs: _previousAttrs: {
          installPhase = ''
            runHook preInstall

            # Inject skip-intro-button.js script for Intro Skipper plugin
            sed -i "s#</head>#<script src=\"configurationpage?name=skip-intro-button.js\"></script></head>#" dist/index.html

            mkdir -p $out/share
            cp -a dist $out/share/jellyfin-web

            runHook postInstall
          '';
        });
      })
    ];

    # Create media directory with proper permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir} 0775 ${homelab.user} ${homelab.group} - -"
    ];

    # Jellyfin service
    services.jellyfin = {
      enable = true;
      user = homelab.user;
      group = homelab.group;
      openFirewall = !homelab.services.enableReverseProxy;
    };

    # Add homelab user to video/render groups for Intel Quick Sync hardware acceleration
    users.users.${homelab.user}.extraGroups = ["video" "render"];

    # Caddy reverse proxy
    services.caddy.virtualHosts = lib.mkIf homelab.services.enableReverseProxy {
      "http://${homelab.hostname}:${toString cfg.port}" = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString cfg.port}
        '';
      };
    };
  };
}
