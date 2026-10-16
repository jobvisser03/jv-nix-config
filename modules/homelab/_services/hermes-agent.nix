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
  googleAuthFiles = map (f: "${hermesHome}/${f}") ["google_token.json" "google_oauth_pending.json"];
  mcpTokensDir = "${hermesHome}/mcp-tokens";
  sharedAuthPaths = googleAuthFiles ++ [mcpTokensDir];
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

  # `google` extra backs the bundled google-workspace skill; its `--install-deps`
  # can't write to the store.
  hermesPackage = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.minimal.override {
    extraDependencyGroups = ["messaging" "google"];
  };

  # Bundled skills shell out to `python`; point it at Hermes' own venv so their
  # deps (google-api-python-client etc.) resolve.
  hermesPython = pkgs.runCommand "hermes-python" {} ''
    mkdir -p "$out/bin"
    ln -s ${hermesPackage.hermesVenv}/bin/python3 "$out/bin/python"
    ln -s ${hermesPackage.hermesVenv}/bin/python3 "$out/bin/python3"
  '';

  # The host CLI runs as `hermes`: Hermes fchmods its state files (memory
  # locks, state.db) to 0600 on every use, which only the file owner may do,
  # so group access alone fails with EPERM for the CLI user.
  stateDir = config.services.hermes-agent.stateDir;
  hermesAsService = pkgs.writeShellScript "hermes-as-service" ''
    export HOME=${stateDir} HERMES_HOME=${hermesHome}
    export PATH=/etc/profiles/per-user/hermes/bin:/run/wrappers/bin:/run/current-system/sw/bin
    cd ${stateDir}
    exec ${hermesPackage}/bin/hermes "$@"
  '';
  hermesCli = lib.hiPrio (pkgs.writeShellScriptBin "hermes" ''
    if [ "$(${pkgs.coreutils}/bin/id -un)" = hermes ]; then
      exec ${hermesAsService} "$@"
    fi
    exec /run/wrappers/bin/sudo -u hermes ${hermesAsService} "$@"
  '');
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
      package = hermesPackage;
      extraPlugins = [rtkPlugin];
      # The package wrapper puts rg/node/ffmpeg on Hermes' own PATH, but the
      # terminal tool's shell (file search, skill scripts) only sees these.
      extraPackages = [pkgs.signal-cli pkgs.rtk hermesPython pkgs.ripgrep pkgs.nodejs pkgs.ffmpeg];
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
      wants = ["hermes-signal-cli.service" "hermes-google-client-secret.service"];
      after = ["hermes-signal-cli.service" "hermes-google-client-secret.service"];
    };

    # Hermes rejects credential files that resolve outside HERMES_HOME, so the
    # SOPS secret is copied in rather than symlinked.
    systemd.services.hermes-google-client-secret = {
      description = "Install Google Workspace OAuth client secret for Hermes";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        rm -f ${hermesHome}/google_client_secret.json
        install -m 0600 -o hermes -g hermes \
          ${config.sops.secrets.google_workspace_oauth_client_secret_json.path} \
          ${hermesHome}/google_client_secret.json
      '';
    };

    networking.firewall.allowedTCPPorts = [cfg.port];

    sops = {
      secrets = {
        # Hermes Desktop remote gateway authentication
        hermes_dashboard_basic_auth_username.mode = "0400";
        hermes_dashboard_basic_auth_password.mode = "0400";
        hermes_dashboard_basic_auth_secret.mode = "0400";
        signal_account.mode = "0400";

        # Google Workspace OAuth desktop client, copied to where the skill looks for it.
        google_workspace_oauth_client_secret_json.restartUnits = ["hermes-google-client-secret.service"];
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
    systemd.tmpfiles.rules =
      [
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
        # MCP OAuth tokens: shared with the CLI user (`~` keeps x bits on the dir only).
        "d ${mcpTokensDir} 0770 hermes hermes - -"
        "Z ${mcpTokensDir} ~0770 hermes hermes - -"
      ]
      ++ map (f: "z ${f} 0660 hermes hermes - -") googleAuthFiles;

    # Auth state is written with the writer's owner and a private mode (Hermes
    # hardcodes 0600 files / 0700 dir for MCP tokens), so whichever of `hermes`
    # or the CLI user writes it, the other loses access. Re-apply the tmpfiles
    # rules above on every write.
    systemd.paths.hermes-auth-perms = {
      wantedBy = ["paths.target"];
      pathConfig.PathChanged = sharedAuthPaths;
    };
    systemd.services.hermes-auth-perms = {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${config.systemd.package}/bin/systemd-tmpfiles --create ${lib.concatMapStringsSep " " (p: "--prefix=${p}") sharedAuthPaths}";
      };
    };

    # The skill shells out to `python`; the CLI user needs Hermes' venv too.
    environment.systemPackages = [hermesPython hermesCli];

    security.sudo.extraRules = [
      {
        users = [username];
        runAs = "hermes";
        commands = [
          {
            command = "${hermesAsService}";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
    security.sudo.extraConfig = ''
      Defaults!${hermesAsService} env_keep += "COLORTERM"
    '';

    # Let host user use same state as gateway CLI.
    users.users.${username}.extraGroups = ["hermes"];
  };
}
