# Hermes Agent - centralized homelab gateway
#
# Secrets come from the host's `sops.defaultSopsFile` (OPENROUTER_API_KEY from
# llm-secrets). Enable on one host only: the Signal channel is a single
# signal-cli account.
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

    listenAddress = lib.mkOption {
      type = lib.types.str;
      example = "192.168.178.43";
      description = "LAN address the Hermes backend (dashboard / Hermes Desktop) binds to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9119;
      description = "Port of the Hermes backend.";
    };
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
        host = cfg.listenAddress;
        inherit (cfg) port;
      };
      settings = {
        model.base_url = "https://openrouter.ai/api/v1";
        model.default = "openai/gpt-6-luna";
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

    networking.firewall.allowedTCPPorts = [cfg.port];

    sops = {
      secrets = {
        # Hermes Desktop remote gateway authentication
        hermes_dashboard_basic_auth_username.mode = "0400";
        hermes_dashboard_basic_auth_password.mode = "0400";
        hermes_dashboard_basic_auth_secret.mode = "0400";
        signal_account.mode = "0400";

        # Google Workspace OAuth desktop client; consumed once by the Hermes setup helper.
        google_workspace_oauth_client_secret_json = {
          owner = "hermes";
          group = "hermes";
          mode = "0400";
        };
      };

      # Hermes reads KEY=VALUE files, so render SOPS secrets into runtime env format.
      templates."hermes-agent.env" = {
        content = ''
          OPENROUTER_API_KEY=${config.sops.placeholder.openrouter_api_key}
          HERMES_DASHBOARD_BASIC_AUTH_USERNAME=${config.sops.placeholder.hermes_dashboard_basic_auth_username}
          HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${config.sops.placeholder.hermes_dashboard_basic_auth_password}
          HERMES_DASHBOARD_BASIC_AUTH_SECRET=${config.sops.placeholder.hermes_dashboard_basic_auth_secret}
          SIGNAL_ACCOUNT=${config.sops.placeholder.signal_account}
          SIGNAL_ALLOWED_USERS=${config.sops.placeholder.signal_account}
        '';
        owner = "root";
        mode = "0400";
      };

      templates."signal-cli.env" = {
        content = ''
          SIGNAL_ACCOUNT=${config.sops.placeholder.signal_account}
        '';
        owner = "root";
        mode = "0400";
      };
    };

    # Keep service and interactive state access aligned. The gateway/backend run as
    # `hermes`, while the host CLI user is in the `hermes` group.
    systemd.tmpfiles.rules = [
      "d ${hermesHome}/runtime 2770 hermes hermes - -"
      # Normalize existing files created by the CLI user, while preserving their modes.
      "Z ${hermesHome}/runtime - hermes hermes - -"
      "z ${hermesHome}/runtime/active_sessions.lock 0660 hermes hermes - -"
      "z ${hermesHome}/runtime/active_sessions.json 0660 hermes hermes - -"
      # CLI prompt history and paste/image dirs: the service creates them 0644/0755,
      # which locks out the CLI user.
      "z ${hermesHome}/.hermes_history 0660 hermes hermes - -"
      "d ${hermesHome}/pastes 2770 hermes hermes - -"
      "d ${hermesHome}/images 2770 hermes hermes - -"
      # MCP OAuth tokens are credentials: keep their directory and files service-owned/private.
      "d ${hermesHome}/mcp-tokens 0700 hermes hermes - -"
      "Z ${hermesHome}/mcp-tokens - hermes hermes - -"
    ];

    # Let host user use same state as gateway CLI.
    users.users.${username}.extraGroups = ["hermes"];
  };
}
