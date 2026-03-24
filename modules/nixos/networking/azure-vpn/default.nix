# Azure VPN NixOS Module
# Provides complete configuration for Microsoft Azure VPN Client on NixOS
# Based on community solutions from NixOS Discourse
{...}: {
  flake.modules.nixos."nixos/networking/azure-vpn" = {
    config,
    pkgs,
    lib,
    ...
  }:
  let
    cfg = config.services.azure-vpn;
    azureVpn = pkgs.callPackage ./_package.nix {};
  in
  {
    options.services.azure-vpn = {
      enable = lib.mkEnableOption "Microsoft Azure VPN Client";

      user = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Username that will run the Azure VPN client (for D-Bus policy)";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Open UDP port 1194 for OpenVPN traffic";
      };
    };

    config = lib.mkIf cfg.enable {
      # Add the Azure VPN client to system packages
      environment.systemPackages = [
        azureVpn
        pkgs.openresolv
      ];

      # Add DigiCert certificates that Azure VPN requires
      # The client expects .pem files in /etc/ssl/certs/
      environment.etc = {
        "ssl/certs/DigiCert_Global_Root_G2.pem".text = ''
          -----BEGIN CERTIFICATE-----
          MIIDjjCCAnagAwIBAgIQAzrx5qcRqaC7KGSxHQn65TANBgkqhkiG9w0BAQsFADBh
          MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
          d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBH
          MjAeFw0xMzA4MDExMjAwMDBaFw0zODAxMTUxMjAwMDBaMGExCzAJBgNVBAYTAlVT
          MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
          b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IEcyMIIBIjANBgkqhkiG
          9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuzfNNNx7a8myaJCtSnX/RrohCgiN9RlUyfuI
          2/Ou8jqJkTx65qsGGmvPrC3oXgkkRLpimn7Wo6h+4FR1IAWsULecYxpsMNzaHxmx
          1x7e/dfgy5SDN67sH0NO3Xss0r0upS/kqbitOtSZpLYl6ZtrAGCSYP9PIUkY92eQ
          q2EGnI/yuum06ZIya7XzV+hdG82MHauVBJVJ8zUtluNJbd134/tJS7SsVQepj5Wz
          tCO7TG1F8PapspUwtP1MVYwnSlcUfIKdzXOS0xZKBgyMUNGPHgm+F6HmIcr9g+UQ
          vIOlCsRnKPZzFBQ9RnbDhxSJITRNrw9FDKZJobq7nMWxM4MphQIDAQABo0IwQDAP
          BgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBhjAdBgNVHQ4EFgQUTiJUIBiV
          5uNu5g/6+rkS7QYXjzkwDQYJKoZIhvcNAQELBQADggEBAGBnKJRvDkhj6zHd6mcY
          1Yl9PMCcit6E7o1xAw7qDz/OGaXvtJCXPMW/QYNBJ/STqEhjY9v3u5p3gLBZTyFM
          uNhM1WrPyKwQGPpvqtdJPlkl0WOXW7wB7g5rQBpHMcKQ7DrFFMoXQqW1+w3A6qHu
          Kd3eNRjEqOxAQ/XPXwZnUoTl70l8zKdPF9VZy2RkE6+y2Cy6N5J2K6d5KaOh5uLo
          9T0kYG8b3A5Q0bU/ek7z7vGf6TySX4CnkPZ7qbHd4yzDICqNkm4r6dwbOkzJ3izT
          UDLMW5cpqCT1GHLQFlBzGMkpJ9QyPJfLMJDzCd2jvF7IIe6eOBMhveCJbyTnoyOJ
          3DY=
          -----END CERTIFICATE-----
        '';

        "ssl/certs/DigiCert_Global_Root_CA.pem".text = ''
          -----BEGIN CERTIFICATE-----
          MIIDrzCCApegAwIBAgIQCDvgVpBCRrGhdWrJWZHHSjANBgkqhkiG9w0BAQUFADBh
          MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
          d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
          QTAeFw0wNjExMTAwMDAwMDBaFw0zMTExMTAwMDAwMDBaMGExCzAJBgNVBAYTAlVT
          MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
          b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IENBMIIBIjANBgkqhkiG
          9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4jvhEXLeqKTTo1eqUKKPC3eQyaKl7hLOllsB
          CSDMAZOnTjC3U/dDxGkAV53ijSLdhwZAAIEJzs4bg7/fzTtxRuLWZscFs3YnFo97
          nh6Vfe63SKMI2tavegw5BmV/Sl0fvBf4q77uKNd0f3p4mVmFaG5cIzJLv07A6Fpt
          43C/dxC//AH2hdmoRBBYMql1GNXRor5H4idq9Joz+EkIYIvUX7Q6hL+hqkpMfT7P
          T19sdl6gSzeRntwi5m3OFBqOasv+zbMUZBfHWymeMr/y7vrTC0LUq7dBMtoM1O/4
          gdW7jVg/tRvoSSiicNoxBN33shbyTApOB6jtSj1etX+jkMOvJwIDAQABo2MwYTAO
          BgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUA95QNVbR
          TLtm8KPiGxvDl7I90VUwHwYDVR0jBBgwFoAUA95QNVbRTLtm8KPiGxvDl7I90VUw
          DQYJKoZIhvcNAQEFBQADggEBAMucN6pIExIK+t1EnE9SsPTfrgT1eXkIoyQY/Esr
          hMAtudXH/vTBH1jLuG2cenTnmCmrEbXjcKChzUyImZOMkXDiqw8cvpOp/2PV5Adg
          06O/nVsJ8dWO41P0jmP6P6fbtGbfYmbW0W5BjfIttep3Sp+dWOIrWcBAI+0tKIJF
          PnlUkiaY4IBIqDfv8NZ5YBberOgOzW6sRBc4L0na4UU+Krk2U886UAb3LujEV0ls
          YSEY1QSteDwsOoBrp+uvFRTp2InBuThs4pFsiv9kuXclVzDAGySj4dzp30d8tbQk
          CAUw7C29C79Fv1C5qfPrmAESrciIxpg0X40KPMbp1ZWVbd4=
          -----END CERTIFICATE-----
        '';
      };

      # Security wrapper with required capabilities for VPN operations
      security.wrappers.microsoft-azurevpnclient = {
        owner = "root";
        group = "root";
        capabilities = "cap_net_admin,cap_net_raw,cap_net_bind_service,cap_setpcap,cap_setuid,cap_setgid,cap_sys_admin+ep";
        source = "${azureVpn}/bin/microsoft-azurevpnclient";
      };

      # systemd-resolved for DNS management (required by Azure VPN)
      services.resolved = {
        enable = true;
        dnssec = "false";
        domains = [ "~." ];
        fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
        settings = {
          Resolve = {
            DNSStubListener = "yes";
            ResolveUnicastSingleLabel = "yes";
            Cache = "yes";
          };
        };
      };

      # systemd-resolved service configuration
      systemd.services.systemd-resolved = {
        serviceConfig = {
          SupplementaryGroups = [ "systemd-network" ];
          BusName = "org.freedesktop.resolve1";
        };
      };

      # D-Bus policies for DNS resolution
      services.dbus.packages = [
        pkgs.gnome-keyring
        (pkgs.writeTextFile {
          name = "azurevpn-dbus-policy";
          destination = "/share/dbus-1/system.d/org.freedesktop.resolve1.AzureVPN.conf";
          text = ''
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
            "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
            <busconfig>
              <policy user="root">
                <allow own="org.freedesktop.resolve1"/>
                <allow send_destination="org.freedesktop.resolve1"/>
              </policy>

              <!-- Allow all users to set DNS -->
              <policy context="default">
                <allow send_destination="org.freedesktop.resolve1"
                       send_interface="org.freedesktop.resolve1.Manager"
                       send_member="SetLinkDNS"/>
                <allow send_destination="org.freedesktop.resolve1"
                       send_interface="org.freedesktop.resolve1.Manager"
                       send_member="SetLinkDomains"/>
                <allow send_destination="org.freedesktop.resolve1"
                       send_interface="org.freedesktop.resolve1.Manager"
                       send_member="SetLinkDefaultRoute"/>
                <allow send_destination="org.freedesktop.resolve1"
                       send_interface="org.freedesktop.resolve1.Manager"
                       send_member="RevertLink"/>
                <allow send_destination="org.freedesktop.resolve1"
                       send_interface="org.freedesktop.DBus.Properties"
                       send_member="Get"/>
                <allow send_destination="org.freedesktop.resolve1"
                       send_interface="org.freedesktop.DBus.Properties"
                       send_member="GetAll"/>
                <allow send_destination="org.freedesktop.resolve1"
                       send_interface="org.freedesktop.DBus.Introspectable"
                       send_member="Introspect"/>
                <allow send_destination="org.freedesktop.resolve1"
                       send_interface="org.freedesktop.DBus.Peer"
                       send_member="Ping"/>
              </policy>
              ${lib.optionalString (cfg.user != "") ''

              <!-- Specific policy for configured user -->
              <policy user="${cfg.user}">
                <allow send_destination="org.freedesktop.resolve1"/>
              </policy>
              ''}
            </busconfig>
          '';
        })
      ];

      # Polkit rules for VPN and DNS operations
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          // Allow DNS and network operations for Azure VPN
          if (action.id.indexOf("org.freedesktop.resolve1.") == 0 ||
              action.id.indexOf("org.freedesktop.NetworkManager.") == 0) {
            // Check if it's our VPN client
            if (subject.programPath &&
                (subject.programPath.indexOf("microsoft-azurevpnclient") >= 0 ||
                 subject.programPath.indexOf("openvpn") >= 0)) {
              return polkit.Result.YES;
            }

            if (subject.local && subject.active && subject.isInGroup("networkmanager")) {
              return polkit.Result.YES;
            }
          }

          // Allow specific DNS operations
          if (action.id == "org.freedesktop.resolve1.set-dns-servers" ||
              action.id == "org.freedesktop.resolve1.set-domains" ||
              action.id == "org.freedesktop.resolve1.set-default-route" ||
              action.id == "org.freedesktop.resolve1.set-link-dns" ||
              action.id == "org.freedesktop.resolve1.set-link-domains" ||
              action.id == "org.freedesktop.resolve1.set-link-default-route" ||
              action.id == "org.freedesktop.resolve1.revert-link") {
            return polkit.Result.YES;
          }
        });
      '';

      # Firewall configuration
      networking.firewall = lib.mkIf cfg.openFirewall {
        allowedUDPPorts = [ 1194 ];
        checkReversePath = lib.mkDefault "loose";
      };

      # Ensure user is in required groups if specified
      users.users = lib.mkIf (cfg.user != "") {
        ${cfg.user} = {
          extraGroups = [ "systemd-network" "network" "networkmanager" ];
        };
      };
    };
  };
}
