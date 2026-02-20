# Homepage Dashboard - Service discovery and monitoring dashboard
{lib, ...}: {
  flake.modules.homelab.homepage = {
    config,
    pkgs,
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

      customLinks = lib.mkOption {
        type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
        default = [];
        description = "Additional links to show in the Misc category";
      };

      jellyfin = {
        apiKeyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to file containing Jellyfin API key for widget stats";
        };
      };
    };

    config = lib.mkIf cfg.enable {
      services.glances = {
        enable = true;
        port = 61208;
      };

      services.homepage-dashboard = {
        enable = true;
        listenPort = cfg.port;
        openFirewall = !homelab.services.enableReverseProxy;

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

        services = let
          hl = homelab.services;
          mkServiceEntry = name: serviceCfg:
            lib.optional serviceCfg.enable {
              "${serviceCfg.homepage.name}" = {
                icon = serviceCfg.homepage.icon;
                description = serviceCfg.homepage.description;
                href = "http://${homelab.hostname}:${toString serviceCfg.port}";
                siteMonitor = "http://127.0.0.1:${toString serviceCfg.port}";
              };
            };

          mediaServices =
            (lib.optionals (hl.immich.enable or false) (mkServiceEntry "immich" hl.immich))
            ++ (lib.optionals (hl.spotify-player.enable or false) [
              {
                "${hl.spotify-player.homepage.name}" = {
                  icon = hl.spotify-player.homepage.icon;
                  description = hl.spotify-player.homepage.description;
                };
              }
            ]);

          smartHomeServices =
            lib.optionals (hl.homeassistant.enable or false) (mkServiceEntry "homeassistant" hl.homeassistant);

          regularServices =
            lib.optionals (hl.paperless.enable or false) (mkServiceEntry "paperless" hl.paperless);

          glancesPort = toString config.services.glances.port;
        in [
          {Media = mediaServices;}
          {Services = regularServices;}
          {"Smart Home" = smartHomeServices;}
          {Misc = cfg.customLinks;}
          {
            System = [
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

      services.caddy.virtualHosts = lib.mkIf homelab.services.enableReverseProxy {
        "http://:80" = {
          extraConfig = ''
            reverse_proxy http://127.0.0.1:${toString cfg.port} {
              header_up Host {host}
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
          '';
        };
      };

      systemd.services.homepage-dashboard.environment =
        {
          HOMEPAGE_ALLOWED_HOSTS = lib.mkForce "${homelab.hostname},localhost,127.0.0.1";
        }
        // lib.optionalAttrs (cfg.jellyfin.apiKeyFile != null) {
          HOMEPAGE_FILE_JELLYFIN_API_KEY = cfg.jellyfin.apiKeyFile;
        };
    };
  };
}
