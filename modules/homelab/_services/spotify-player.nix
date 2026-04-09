# Spotify launcher - HTTP endpoint to launch Spotify desktop app via Hyprland
# The Spotify desktop app provides Spotify Connect, allowing streaming from
# phone/tablet to larkbox's speakers. This service provides a simple HTTP
# endpoint to ensure Spotify is running, usable from Homepage or any browser.
{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.homelab.services.spotify-player;
  homelab = config.homelab;

  # Script that launches Spotify via hyprctl if not already running
  launchScript = pkgs.writeShellScript "spotify-launch" ''
    HYPRLAND_INSTANCE_SIGNATURE=$(ls /tmp/hypr/ 2>/dev/null | head -1)
    export HYPRLAND_INSTANCE_SIGNATURE

    if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
      echo "Hyprland is not running"
      exit 1
    fi

    HYPRCTL="${pkgs.hyprland}/bin/hyprctl"

    # Check if Spotify is already running
    if $HYPRCTL clients -j | ${pkgs.jq}/bin/jq -e '.[] | select(.class == "spotify")' > /dev/null 2>&1; then
      echo "Spotify is already running"
    else
      # Toggle the special workspace which triggers on-created-empty:spotify
      $HYPRCTL dispatch togglespecialworkspace spotify
      sleep 2
      # Hide the workspace again so it doesn't stay visible
      $HYPRCTL dispatch togglespecialworkspace spotify
      echo "Spotify launched"
    fi
  '';

  # Python HTTP server that triggers the launch script on any request
  httpServer = pkgs.writeText "spotify-launcher-server.py" ''
    import http.server
    import subprocess
    import sys

    PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8090

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            result = subprocess.run(
                ["${launchScript}"],
                capture_output=True, text=True, timeout=15
            )
            output = result.stdout.strip() or result.stderr.strip() or "No output"
            ok = result.returncode == 0

            self.send_response(200 if ok else 500)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            status = "✓" if ok else "✗"
            self.wfile.write(f"""<html>
    <head><meta http-equiv="refresh" content="2;url=/"></head>
    <body style="font-family:system-ui;padding:2rem">
      <h2>{status} {output}</h2>
      <p>Redirecting to homepage...</p>
    </body></html>""".encode())

        def log_message(self, format, *args):
            print(f"[spotify-launcher] {args[0]}", flush=True)

    server = http.server.HTTPServer(("127.0.0.1", PORT), Handler)
    print(f"Spotify launcher listening on 127.0.0.1:{PORT}", flush=True)
    server.serve_forever()
  '';
in {
  options.homelab.services.spotify-player = {
    enable = lib.mkEnableOption "Spotify launcher - HTTP endpoint to start Spotify";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8090;
      description = "Port for the Spotify launcher HTTP endpoint";
    };

    # Homepage dashboard integration
    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Spotify";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Launch Spotify (Connect speaker)";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "spotify.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Media";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Systemd service for the HTTP launcher endpoint
    systemd.services.spotify-launcher = {
      description = "Spotify Launcher HTTP Endpoint";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = username;
        Group = "users";
        ExecStart = "${pkgs.python3}/bin/python3 ${httpServer} ${toString cfg.port}";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
