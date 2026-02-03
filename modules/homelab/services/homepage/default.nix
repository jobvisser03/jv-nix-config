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

        # Build service entry if enabled
        mkServiceEntry = name: serviceCfg:
          lib.optional serviceCfg.enable {
            "${serviceCfg.homepage.name}" = {
              icon = serviceCfg.homepage.icon;
              description = serviceCfg.homepage.description;
              href = "http://${homelab.hostname}:${toString serviceCfg.port}";
              siteMonitor = "http://127.0.0.1:${toString serviceCfg.port}";
            };
          };

        # Group services by category
        mediaServices =
          (lib.optionals (hl.immich.enable or false) (mkServiceEntry "immich" hl.immich));

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
  };
}
