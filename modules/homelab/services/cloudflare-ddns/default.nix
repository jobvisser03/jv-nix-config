{
  config,
  lib,
  pkgs,
  ...
}: let
  service = "cloudflare-ddns";
  cfg = config.homelab.services.cloudflare-ddns;
in {
  options.homelab.services.cloudflare-ddns = {
    enable = lib.mkEnableOption "Cloudflare Dynamic DNS updater";

    zoneId = lib.mkOption {
      type = lib.types.str;
      description = "Cloudflare Zone ID for the domain";
    };

    recordName = lib.mkOption {
      type = lib.types.str;
      description = "Fully qualified DNS record name to update (e.g. home.dutchdataworks.nl)";
    };

    tokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing Cloudflare API token";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "5min";
      description = "How often to run the DDNS update (systemd timer OnUnitActiveSec)";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.cloudflare-ddns = {
      description = "Update Cloudflare A record with current public IP";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "cloudflare-ddns" ''
          set -euo pipefail

          TOKEN=$(cat ${cfg.tokenFile})
          ZONE_ID=${cfg.zoneId}
          RECORD_NAME=${cfg.recordName}

          # Detect current public IPv4
          CURRENT_IP=$(curl -s https://checkip.cloudflare.com || curl -s https://api.ipify.org)

          if [ -z "$CURRENT_IP" ]; then
            echo "Failed to determine current public IP" >&2
            exit 1
          fi

          API=https://api.cloudflare.com/client/v4

          # Look up existing record
          RECORD_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
            "$API/zones/$ZONE_ID/dns_records?type=A&name=$RECORD_NAME")

          RECORD_ID=$(echo "$RECORD_RESPONSE" | ${pkgs.jq}/bin/jq -r '.result[0].id // empty')
          OLD_IP=$(echo "$RECORD_RESPONSE" | ${pkgs.jq}/bin/jq -r '.result[0].content // empty')

          if [ -z "$RECORD_ID" ]; then
            echo "Record $RECORD_NAME not found, creating it" >&2
            CREATE_PAYLOAD=$(printf '{"type":"A","name":"%s","content":"%s","ttl":300,"proxied":false}' "$RECORD_NAME" "$CURRENT_IP")
            curl -s -X POST "$API/zones/$ZONE_ID/dns_records" \
              -H "Authorization: Bearer $TOKEN" \
              -H "Content-Type: application/json" \
              --data "$CREATE_PAYLOAD" >/dev/null
            exit 0
          fi

          if [ "$CURRENT_IP" = "$OLD_IP" ]; then
            echo "IP unchanged ($CURRENT_IP), nothing to do" >&2
            exit 0
          fi

          echo "Updating $RECORD_NAME from $OLD_IP to $CURRENT_IP" >&2
          UPDATE_PAYLOAD=$(printf '{"type":"A","name":"%s","content":"%s","ttl":300,"proxied":false}' "$RECORD_NAME" "$CURRENT_IP")
          curl -s -X PUT "$API/zones/$ZONE_ID/dns_records/$RECORD_ID" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            --data "$UPDATE_PAYLOAD" >/dev/null
        '';
      };
    };

    systemd.timers.${service} = {
      description = "Cloudflare DDNS";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnUnitActiveSec = cfg.interval;
        Unit = "${service}.service";
      };
    };
  };
}
