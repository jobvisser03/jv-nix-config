# Homeserver: headless NAS + media server.
#
# Ryzen 5 7600 / ASRock B650M RS Pro / 32 GB ECC / 1 TB NVMe (LUKS root) /
# 5x 10 TB HDD (ZFS RAIDZ2 `tank`). Console access via JetKVM.
# Also runs a Tang server so the framework can unlock when larkbox is down.
#
# Immich and Jellyfin are preconfigured against tank but disabled until
# they are migrated off larkbox. See docs/homeserver/overview.md.
{...}: {
  flake.modules.nixos."hosts/homeserver" = {
    config,
    lib,
    pkgs,
    inputs,
    username,
    ...
  }: let
    # framework-13-pro. Used for normal SSH and the initrd unlock SSH.
    adminKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2mNxAxH9uxUJ+Mk5dwTaIKU7iApm4HYPFhiKtkJ0VF job@dutchdataworks.nl"
    ];

    # The ZFS pool and everything on /tank (shares, pCloud sync, snapshots).
    # false = NVMe-only system; flip once all five HDDs are connected and
    # `tank` has been created. See docs/homeserver/install.md#creating-tank-later.
    tank = false;
  in {
    imports =
      [
        ./_hardware-configuration.nix
        ./_disko-nvme.nix
        ./_secrets.nix
        ./_storage.nix
        inputs.disko.nixosModules.disko
        inputs.lanzaboote.nixosModules.lanzaboote
      ]
      ++ lib.optionals tank [
        ./_disko-tank.nix
        ./_tank.nix
        ./_shares.nix
        ./_pcloud.nix
      ];

    networking.hostName = "homeserver";

    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    # Key-only SSH, as on Riezebos/nix foundry. Passwordless sudo makes a
    # guessed password equal to root, so password logins stay off.
    users.users.${username}.openssh.authorizedKeys.keys = adminKeys;
    services.openssh.settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };

    # Secure Boot via Lanzaboote, same flow as framework-13-pro: install with
    # Secure Boot off, keys are generated on first boot, enroll, enforce.
    # It makes the TPM2 PCR 7 seal meaningful: booting other media changes
    # PCR 7, so the TPM refuses even while Tang is reachable.
    boot.loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = true;
    };
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      autoGenerateKeys.enable = true;
      configurationLimit = 10;
    };
    # Terminfo for the client terminals, so SSH from kitty/wezterm gets a sane TERM.
    environment.systemPackages = [pkgs.sbctl pkgs.kitty.terminfo pkgs.wezterm.terminfo];

    # Unattended LUKS unlock: TPM2 (PCR 7) AND Tang on larkbox. If either is
    # missing, unlock over SSH (port 2222, initrd) or type it via JetKVM.
    # See docs/network-unlock.md.
    networkUnlock = {
      enable = true;
      tpm2Pcrs = "7";
      # Onboard Realtek 2.5GbE (driver confirmed on the installed box 2026-10-13).
      initrdKernelModules = ["r8169"];
      ssh = {
        enable = true;
        authorizedKeys = adminKeys;
      };
    };

    # No swap partition; compressed RAM swap absorbs Immich ML spikes.
    zramSwap.enable = true;

    networking.firewall = {
      enable = true;
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = [41641];
    };
    services.tailscale.useRoutingFeatures = "server";

    # Ryzen 7600 iGPU (RDNA2): VAAPI via Mesa radeonsi for Jellyfin/Immich
    # transcoding. Keep the iGPU enabled in firmware (UMA frame buffer).
    hardware.graphics.enable = true;

    homelab = {
      enable = true;
      # Caddy, public HTTPS and DDNS stay on larkbox until migration day.
      services.enable = false;
      domain = "dutchdataworks.nl";

      services.immich = {
        enable = false;
        mediaDir = "/tank/immich";
        externalLibraryDirs = [
          "/tank/photos/PHOTOS-PCLOUD"
          "/tank/photos/SMARTPHONE-PHOTOS-PCLOUD"
        ];
      };

      services.jellyfin = {
        enable = false;
        mediaDir = "/tank/media";
      };

      # Signal / dashboard gateway, moved from larkbox. Secrets in secrets/homeserver.yaml.
      services.hermes-agent = {
        enable = true;
        listenAddress = "192.168.178.43";
      };

      # Vault inside Hermes' workspace: its terminal tool starts there and the
      # service sandbox allows writes. Owned by `hermes`, so no ACLs are needed.
      services.obsidian-vault = {
        enable = true;
        user = "hermes";
        group = "hermes";
        dir = "${config.services.hermes-agent.workingDirectory}/obsidian_vault";
      };
    };

    # Point Hermes' bundled `obsidian` skill at the vault. Written to
    # $HERMES_HOME/.env, so the gateway and the `hermes` CLI both see it.
    services.hermes-agent.environment.OBSIDIAN_VAULT_PATH = config.homelab.services.obsidian-vault.dir;

    # Services on tank must wait for the (nofail) pool mounts.
    systemd.services = lib.mkMerge [
      (lib.mkIf config.homelab.services.immich.enable {
        immich-server.unitConfig.RequiresMountsFor = ["/tank/immich" "/tank/photos"];
      })
      (lib.mkIf config.homelab.services.jellyfin.enable {
        jellyfin.unitConfig.RequiresMountsFor = ["/tank/media"];
      })
    ];

    assertions = [
      {
        assertion =
          lib.all (disk: !(lib.hasInfix "REPLACE-ME" disk.device))
          (lib.attrValues config.disko.devices.disk);
        message = "homeserver: replace REPLACE-ME disk ids in _disko-nvme.nix / _disko-tank.nix with /dev/disk/by-id paths.";
      }
      {
        assertion = tank || !(config.homelab.services.immich.enable || config.homelab.services.jellyfin.enable);
        message = "homeserver: Immich and Jellyfin store their data on /tank; set `tank = true` first.";
      }
    ];

    system.stateVersion = "26.05";
  };
}
