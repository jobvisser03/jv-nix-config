# Network-bound disk encryption (NBDE): Clevis + Tang + TPM2.
#
# Two modules live here:
#   - "nixos/network-unlock": LUKS client. The root volume unlocks
#     automatically only when BOTH the local TPM2 (sealed to PCRs) and a Tang
#     server on the home LAN answer. Off-LAN, or after firmware/Secure Boot
#     changes, the normal passphrase prompt still works.
#   - "nixos/tang-server": Tang on the home LAN (larkbox, homeserver).
#
# Policy shape (clevis sss, threshold 2):
#   one Tang server:   {t:2, pins:{tpm2, tang:[A]}}
#   several servers:   {t:2, pins:{tpm2, sss:{t:1, pins:{tang:[A,B]}}}}
# so any reachable Tang plus the TPM unlocks, but two Tang servers without
# the TPM (stolen disk on the LAN) never do.
#
# Bindings live in the LUKS2 header, not in Nix. Enroll with the generated
# `network-unlock` helper; see docs/network-unlock.md.
{...}: let
  # Home LAN (FritzBox). Tang only answers on this subnet.
  lanSubnet = "192.168.178.0/24";
  tangPort = 7654;
in {
  flake.modules.nixos."nixos/network-unlock" = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.networkUnlock;
    luksDevice = config.boot.initrd.luks.devices.${cfg.luksDevice}.device;
    wifiConf = "/etc/secrets/initrd/wpa_supplicant.conf";

    helper = pkgs.writeShellApplication {
      name = "network-unlock";
      runtimeInputs = with pkgs; [
        clevis
        coreutils
        cryptsetup
        curl
        gnugrep
        gnused
        jose
        jq
        networkmanager
        systemd
        wpa_supplicant
      ];
      text =
        ''
          DEVICE=${lib.escapeShellArg luksDevice}
          TANG_URLS=(${lib.escapeShellArgs cfg.tangServers})
          TPM2_PCRS=${lib.escapeShellArg cfg.tpm2Pcrs}
          WIFI_INTERFACE=${lib.escapeShellArg (lib.optionalString cfg.wifi.enable cfg.wifi.interface)}
          WIFI_CONF=${lib.escapeShellArg wifiConf}
        ''
        + builtins.readFile ./_network-unlock.sh;
    };
  in {
    options.networkUnlock = {
      enable = lib.mkEnableOption "Clevis Tang + TPM2 unlock of the LUKS root";

      luksDevice = lib.mkOption {
        type = lib.types.str;
        default = "cryptroot";
        description = "Name of the boot.initrd.luks.devices entry to unlock.";
      };

      tangServers = lib.mkOption {
        type = lib.types.nonEmptyListOf lib.types.str;
        # larkbox. Needs a DHCP reservation: the initrd has no mDNS/DNS.
        default = ["http://192.168.178.190:${toString tangPort}"];
        description = "Tang URLs; any one of them plus the TPM2 unlocks.";
      };

      tpm2Pcrs = lib.mkOption {
        type = lib.types.str;
        default = "7";
        description = "PCRs the TPM2 pin seals against. 7 = Secure Boot policy.";
      };

      initrdKernelModules = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["r8169"];
        description = "NIC drivers (and firmware users) needed to reach Tang from the initrd.";
      };

      initrdFirmware = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Firmware files not listed in modinfo, relative to lib/firmware.";
      };

      wifi = {
        enable = lib.mkEnableOption "Wi-Fi in the initrd (WPA-PSK of the current home network)";
        interface = lib.mkOption {
          type = lib.types.str;
          default = "";
          example = "wlp0s20f3";
          description = "Wireless interface name, as seen by the running system.";
        };
      };

      ssh = {
        enable = lib.mkEnableOption "SSH in the initrd as a remote passphrase fallback";
        port = lib.mkOption {
          type = lib.types.port;
          default = 2222;
        };
        authorizedKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };
      };
    };

    config = lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = config.boot.initrd.luks.devices ? ${cfg.luksDevice};
          message = "networkUnlock: boot.initrd.luks.devices.${cfg.luksDevice} does not exist.";
        }
        {
          assertion = !cfg.wifi.enable || cfg.wifi.interface != "";
          message = "networkUnlock.wifi.interface must be set when Wi-Fi unlock is enabled.";
        }
        {
          assertion = !cfg.ssh.enable || cfg.ssh.authorizedKeys != [];
          message = "networkUnlock.ssh.authorizedKeys must not be empty.";
        }
      ];

      boot.initrd = {
        # Clevis answers the systemd password prompt in parallel with the
        # console, so a missing Tang/TPM never blocks typing the passphrase.
        clevisLuksAskpass = {
          enable = true;
          useTang = true;
        };

        availableKernelModules =
          ["tpm_crb" "tpm_tis"]
          ++ cfg.initrdKernelModules
          ++ lib.optionals cfg.wifi.enable ["ccm" "ctr"];
        extraFirmwarePaths =
          cfg.initrdFirmware
          ++ lib.optionals cfg.wifi.enable ["regulatory.db" "regulatory.db.p7s"];

        # Written by `network-unlock wifi`. Must exist before the bootloader
        # install, or the rebuild fails; see docs/network-unlock.md.
        secrets = lib.mkIf cfg.wifi.enable {
          "/etc/network-unlock-wifi.conf" = wifiConf;
        };

        systemd = {
          enable = true;
          storePaths = lib.optionals cfg.wifi.enable ["${pkgs.wpa_supplicant}/bin/wpa_supplicant"];
          network = {
            enable = true;
            # An unreachable Tang or missing link must not gate the prompt.
            wait-online.enable = false;
            networks."10-network-unlock" = {
              matchConfig.Name =
                if cfg.wifi.enable
                then cfg.wifi.interface
                else "en*";
              networkConfig.DHCP = "ipv4";
              linkConfig.RequiredForOnline = "no";
            };
          };

          services.network-unlock-wifi = lib.mkIf cfg.wifi.enable {
            description = "Connect Wi-Fi for Tang disk unlock";
            wantedBy = ["initrd.target"];
            requires = ["initrd-nixos-copy-secrets.service"];
            after = ["systemd-udevd.service" "initrd-nixos-copy-secrets.service"];
            before = ["shutdown.target"];
            conflicts = ["shutdown.target"];
            unitConfig = {
              DefaultDependencies = false;
              StartLimitIntervalSec = 0;
            };
            serviceConfig = {
              ExecStart = "${pkgs.wpa_supplicant}/bin/wpa_supplicant -i ${cfg.wifi.interface} -c /etc/network-unlock-wifi.conf";
              Restart = "on-failure";
              RestartSec = 2;
            };
          };
        };

        network = {
          enable = true;
          # Hand the NIC to NetworkManager without leftover initrd addresses.
          flushBeforeStage2 = true;

          # Remote passphrase entry when Tang or the TPM refuses (headless
          # hosts). The host key is generated at install time.
          ssh = lib.mkIf cfg.ssh.enable {
            enable = true;
            inherit (cfg.ssh) port authorizedKeys;
            hostKeys = ["/etc/secrets/initrd/ssh_host_ed25519_key"];
            # Land on the LUKS prompt instead of an initrd root shell.
            extraConfig = ''
              ForceCommand systemd-tty-ask-password-agent --query
            '';
          };
        };
      };

      environment.systemPackages = [pkgs.clevis helper];
      # Buildable before the first switch: the Wi-Fi secret must exist first.
      #   nix build .#nixosConfigurations.<host>.config.system.build.networkUnlock
      system.build.networkUnlock = helper;
    };
  };

  flake.modules.nixos."nixos/tang-server" = {lib, ...}: {
    # Keys are created on first request under /var/lib/private/tang. Rotating
    # or losing them breaks every binding: clients fall back to passphrase
    # and must run `network-unlock bind --replace`.
    services.tang = {
      enable = true;
      listenStream = [(toString tangPort)];
      ipAddressAllow = [lanSubnet "127.0.0.0/8" "::1/128"];
    };
    networking.firewall.allowedTCPPorts = [tangPort];
  };
}
