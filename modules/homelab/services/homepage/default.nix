# Homepage Dashboard - Service discovery and monitoring dashboard
{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.services.homepage;
  homelab = config.homelab;
in {
  options.homelab.services.homepage = {
    enable = lib.mkEnableOption "Homepage - Modern dashboard for homelab services";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8082;
      description = "Port for Homepage dashboard";
    };

    # Additional custom links to show on the dashboard
    customLinks = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      default = [];
      description = "Additional links to show in the Misc category";
      example = [
        {
          "Router" = {
            href = "http://192.168.1.1";
            icon = "router.svg";
            description = "Home router admin";
          };
        }
      ];
    };

    # Jellyfin widget configuration
    jellyfin = {
      apiKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to file containing Jellyfin API key for widget stats";
        example = "config.sops.secrets.jellyfin_api_key.path";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable Glances for system monitoring
    services.glances = {
      enable = true;
      port = 61208;
    };

    # Homepage dashboard
    services.homepage-dashboard = {
      enable = true;
      listenPort = cfg.port;
      openFirewall = !homelab.services.enableReverseProxy;

      # Custom CSS for cleaner look
      customCSS = ''
        body, html {
          font-family: SF Pro Display, Helvetica, Arial, sans-serif !important;
        }
        .font-medium {
          font-weight: 700 !important;
        }
        .font-light {
          font-weight: 500 !important;
        }
        .font-thin {
          font-weight: 400 !important;
        }
        #information-widgets {
          padding-left: 1.5rem;
          padding-right: 1.5rem;
        }
        div#footer {
          display: none;
        }
      '';

      settings = {
        headerStyle = "clean";
        statusStyle = "dot";
        hideVersion = "true";
        layout = [
          {
            System = {
              header = false;
              style = "row";
              columns = 4;
            };
          }
          {
            Media = {
              header = true;
              style = "column";
            };
          }
          {
            Services = {
              header = true;
              style = "column";
            };
          }
          {
            "Smart Home" = {
              header = true;
              style = "column";
            };
          }
        ];
      };

      # Service discovery - automatically add enabled services
      services = let
        hl = homelab.services;

        # Build service entry if enabled (basic, no widget)
        mkServiceEntry = name: serviceCfg:
          lib.optional serviceCfg.enable {
            "${serviceCfg.homepage.name}" = {
              icon = serviceCfg.homepage.icon;
              description = serviceCfg.homepage.description;
              href = "http://${homelab.hostname}:${toString serviceCfg.port}";
              siteMonitor = "http://127.0.0.1:${toString serviceCfg.port}";
            };
          };

        # Build Jellyfin entry with optional widget (when API key is provided)
        jellyfinEntry =
          lib.optional (hl.jellyfin.enable or false) {
            "${hl.jellyfin.homepage.name}" =
              {
                icon = hl.jellyfin.homepage.icon;
                description = hl.jellyfin.homepage.description;
                href = "http://${homelab.hostname}:${toString hl.jellyfin.port}";
                siteMonitor = "http://127.0.0.1:${toString hl.jellyfin.port}";
              }
              // lib.optionalAttrs (cfg.jellyfin.apiKeyFile != null) {
                widget = {
                  type = "jellyfin";
                  url = "http://127.0.0.1:${toString hl.jellyfin.port}";
                  key = "{{HOMEPAGE_FILE_JELLYFIN_API_KEY}}";
                  enableBlocks = true;
                  enableNowPlaying = true;
                };
              };
          };

        # Group services by category
        mediaServices =
          (lib.optionals (hl.immich.enable or false) (mkServiceEntry "immich" hl.immich))
          ++ jellyfinEntry;

        smartHomeServices =
          (lib.optionals (hl.homeassistant.enable or false) (mkServiceEntry "homeassistant" hl.homeassistant));

        regularServices =
          (lib.optionals (hl.radicale.enable or false) (mkServiceEntry "radicale" hl.radicale));
      in
        [
          {
            Media = mediaServices;
          }
          {
            Services = regularServices;
          }
          {
            "Smart Home" = smartHomeServices;
          }
          {
            Misc = cfg.customLinks;
          }
          {
            System = let
              glancesPort = toString config.services.glances.port;
            in [
              {
                Info = {
                  widget = {
                    type = "glances";
                    url = "http://localhost:${glancesPort}";
                    metric = "info";
                    chart = false;
                    version = 4;
                  };
                };
              }
              {
                CPU = {
                  widget = {
                    type = "glances";
                    url = "http://localhost:${glancesPort}";
                    metric = "cpu";
                    chart = false;
                    version = 4;
                  };
                };
              }
              {
                Memory = {
                  widget = {
                    type = "glances";
                    url = "http://localhost:${glancesPort}";
                    metric = "memory";
                    chart = false;
                    version = 4;
                  };
                };
              }
              {
                Disk = {
                  widget = {
                    type = "glances";
                    url = "http://localhost:${glancesPort}";
                    metric = "disk:sda";
                    chart = false;
                    version = 4;
                  };
                };
              }
            ];
          }
        ];
    };

    # Caddy reverse proxy - serve dashboard at root
    services.caddy.virtualHosts = lib.mkIf homelab.services.enableReverseProxy {
      "http://${homelab.hostname}" = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString cfg.port}
        '';
      };
    };

    # Set up environment variable for Jellyfin API key file
    # Homepage uses HOMEPAGE_FILE_* convention to read secrets from files
    systemd.services.homepage-dashboard.environment = lib.mkIf (cfg.jellyfin.apiKeyFile != null) {
      HOMEPAGE_FILE_JELLYFIN_API_KEY = cfg.jellyfin.apiKeyFile;
    };
  };
}
