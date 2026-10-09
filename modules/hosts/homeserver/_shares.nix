# Network shares: Samba (macOS + Linux) and NFSv4 (Linux).
# Access is limited to the LAN and Tailscale (tailscale0 is a trusted interface).
# Samba users need a password once: `sudo smbpasswd -a <user>`.
{username, ...}: let
  # TODO: verify against the router before first install.
  lanSubnet = "192.168.1.0/24";
  tailnet = "100.64.0.0/10";

  mkShare = path: extra:
    {
      inherit path;
      browseable = "yes";
      "read only" = "no";
      "valid users" = username;
      "create mask" = "0644";
      "directory mask" = "0755";
    }
    // extra;
in {
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "server string" = "homeserver";
        "server min protocol" = "SMB3";
        security = "user";
        "map to guest" = "never";
        "hosts allow" = "${lanSubnet} ${tailnet} 127.0.0.1 ::1";
        "hosts deny" = "0.0.0.0/0";
        # macOS interop (Finder metadata, resource forks)
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
      };
      documents = mkShare "/tank/documents" {};
      media = mkShare "/tank/media" {"force group" = "homelab";};
      backups = mkShare "/tank/backups" {};
      # pCloud mirror: rclone owns the contents, clients only read.
      photos = mkShare "/tank/photos" {"read only" = "yes";};
    };
  };

  # Lets Finder discover the shares via Bonjour.
  services.avahi.extraServiceFiles.smb = ''
    <?xml version="1.0" standalone='no'?>
    <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
    <service-group>
      <name replace-wildcards="yes">%h</name>
      <service>
        <type>_smb._tcp</type>
        <port>445</port>
      </service>
    </service-group>
  '';

  # NFSv4 only: a single TCP port, no rpcbind/mountd exposure.
  services.nfs = {
    server = {
      enable = true;
      exports = let
        opts = "rw,sync,no_subtree_check,root_squash";
        clients = "${lanSubnet}(${opts}) ${tailnet}(${opts})";
      in ''
        /tank/documents ${clients}
        /tank/media     ${clients}
        /tank/backups   ${clients}
      '';
    };
    settings.nfsd = {
      vers3 = false;
      vers4 = true;
    };
  };
  networking.firewall.allowedTCPPorts = [2049];
}
