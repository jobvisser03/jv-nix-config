# Hermes Agent - centralized homelab gateway
{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.homelab.services.hermes-agent;
  hermesHome = "${config.services.hermes-agent.stateDir}/.hermes";
  signalHttpPort = 8081;
  signalCliStart = pkgs.writeShellScript "hermes-signal-cli-start" ''
    exec ${pkgs.signal-cli}/bin/signal-cli --scrub-log --account "$SIGNAL_ACCOUNT" daemon --http 127.0.0.1:${toString signalHttpPort}
  '';

  rtkPluginSrc = pkgs.fetchFromGitHub {
    owner = "kerrz2020";
    repo = "hermes-rtk-rewrite";
    rev = "4c5f8a5abdfd7980cba5ef02df86b8efe52c00d6";
    hash = "sha256-WQbdijsQsWsROVDR2Npwx/IGTQdbNxO4CzNkjwpRS/k=";
  };

  rtkPlugin = pkgs.runCommand "nix-managed-rtk-rewrite" {} ''
    mkdir -p "$out"
    cp -r ${rtkPluginSrc}/. "$out/"
  '';
in {
  options.homelab.services.hermes-agent = {
    enable = lib.mkEnableOption "Hermes Agent gateway";
  };

  config = lib.mkIf cfg.enable {
    services.hermes-agent = {
      enable = true;
      package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.messaging;
      extraPlugins = [rtkPlugin];
      extraPackages = [pkgs.signal-cli pkgs.rtk];
      mcpServers.notion = {
        url = "https://mcp.notion.com/mcp";
        auth = "oauth";
      };
      addToSystemPackages = true;
      environment.SIGNAL_HTTP_URL = "http://127.0.0.1:${toString signalHttpPort}";
      environmentFiles = [config.sops.templates."hermes-agent.env".path];
      backend = {
        mode = "serve";
        host = "192.168.178.190";
        port = 9119;
      };
      settings = {
        model.default = "gpt-6-luna";
        terminal.backend = "local";
        plugins.enabled = ["rtk-rewrite"];
      };
    };

    systemd.services.hermes-signal-cli = {
      description = "signal-cli HTTP daemon for Hermes";
      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"];
      after = ["network-online.target"];
      environment.HOME = config.services.hermes-agent.stateDir;
      serviceConfig = {
        User = "hermes";
        Group = "hermes";
        WorkingDirectory = config.services.hermes-agent.stateDir;
        EnvironmentFile = config.sops.templates."signal-cli.env".path;
        ExecStart = "${signalCliStart}";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    systemd.services.hermes-agent = {
      wants = ["hermes-signal-cli.service"];
      after = ["hermes-signal-cli.service"];
    };

    # Keep service and interactive state access aligned. The gateway/backend run as
    # `hermes`, while the host CLI user is in the `hermes` group.
    systemd.tmpfiles.rules = [
      "d ${hermesHome}/runtime 2770 hermes hermes - -"
      # Normalize existing files created by the CLI user, while preserving their modes.
      "Z ${hermesHome}/runtime - hermes hermes - -"
      "z ${hermesHome}/runtime/active_sessions.lock 0660 hermes hermes - -"
      "z ${hermesHome}/runtime/active_sessions.json 0660 hermes hermes - -"
      # MCP OAuth tokens are credentials: keep their directory and files service-owned/private.
      "d ${hermesHome}/mcp-tokens 0700 hermes hermes - -"
      "Z ${hermesHome}/mcp-tokens - hermes hermes - -"
    ];

    # Let host user use same state as gateway CLI.
    users.users.${username}.extraGroups = ["hermes"];
  };
}
