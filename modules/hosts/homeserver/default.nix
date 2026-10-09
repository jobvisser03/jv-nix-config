# Homeserver: headless NAS + media server.
#
# Ryzen 5 7600 / ASRock B650M RS Pro / 32 GB ECC / 1 TB NVMe (root) /
# 5x 10 TB HDD (ZFS RAIDZ2 `tank`). Console access via JetKVM.
#
# Immich and Jellyfin are preconfigured against tank but disabled until
# they are migrated off larkbox. See docs/homeserver.md.
{...}: {
  flake.modules.nixos."hosts/homeserver" = {
    config,
    lib,
    inputs,
    ...
  }: {
    imports = [
      ./_hardware-configuration.nix
      ./_disko-nvme.nix
      ./_disko-tank.nix
      ./_secrets.nix
      ./_storage.nix
      ./_shares.nix
      ./_pcloud.nix
      inputs.disko.nixosModules.disko
    ];

    networking.hostName = "homeserver";

    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
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
    };

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
    ];

    system.stateVersion = "26.05";
  };
}
