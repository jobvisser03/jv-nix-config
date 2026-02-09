# GitLab - Web-based Git repository management
# https://wiki.nixos.org/wiki/Gitlab
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.gitlab;
  homelab = config.homelab;
in {
  options.homelab.services.gitlab = {
    enable = lib.mkEnableOption "GitLab - Web-based Git repository management";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for GitLab web interface (via Caddy reverse proxy)";
    };

    # Secret file paths - using sops secrets
    secrets = {
      databasePasswordFile = lib.mkOption {
        type = lib.types.path;
        default = config.sops.secrets.gitlab_database_password.path;
        description = "Path to GitLab database password file";
      };

      initialRootPasswordFile = lib.mkOption {
        type = lib.types.path;
        default = config.sops.secrets.gitlab_initial_root_password.path;
        description = "Path to GitLab initial root password file";
      };

      secretFile = lib.mkOption {
        type = lib.types.path;
        default = config.sops.secrets.gitlab_secret.path;
        description = "Path to GitLab secret key base file";
      };

      otpFile = lib.mkOption {
        type = lib.types.path;
        default = config.sops.secrets.gitlab_otp_secret.path;
        description = "Path to GitLab OTP secret file";
      };

      dbFile = lib.mkOption {
        type = lib.types.path;
        default = config.sops.secrets.gitlab_db_secret.path;
        description = "Path to GitLab database secret file";
      };

      jwsFile = lib.mkOption {
        type = lib.types.path;
        default = config.sops.secrets.gitlab_jws_key.path;
        description = "Path to GitLab JWS private key file";
      };

      activeRecordPrimaryKeyFile = lib.mkOption {
        type = lib.types.path;
        default = config.sops.secrets.gitlab_active_record_primary_key.path;
        description = "Path to GitLab Active Record primary key file";
      };

      activeRecordDeterministicKeyFile = lib.mkOption {
        type = lib.types.path;
        default = config.sops.secrets.gitlab_active_record_deterministic_key.path;
        description = "Path to GitLab Active Record deterministic key file";
      };

      activeRecordSaltFile = lib.mkOption {
        type = lib.types.path;
        default = config.sops.secrets.gitlab_active_record_salt.path;
        description = "Path to GitLab Active Record salt file";
      };
    };

    # Homepage dashboard integration
    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "GitLab";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Web-based Git repository management";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "gitlab.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # GitLab service configuration
    services.gitlab = {
      enable = true;
      databasePasswordFile = cfg.secrets.databasePasswordFile;
      initialRootPasswordFile = cfg.secrets.initialRootPasswordFile;
      secrets = {
        secretFile = cfg.secrets.secretFile;
        otpFile = cfg.secrets.otpFile;
        dbFile = cfg.secrets.dbFile;
        jwsFile = cfg.secrets.jwsFile;
        activeRecordPrimaryKeyFile = cfg.secrets.activeRecordPrimaryKeyFile;
        activeRecordDeterministicKeyFile = cfg.secrets.activeRecordDeterministicKeyFile;
        activeRecordSaltFile = cfg.secrets.activeRecordSaltFile;
      };
    };

    # Caddy reverse proxy
    # GitLab uses a Unix socket at /run/gitlab/gitlab-workhorse.socket
    services.caddy.virtualHosts = lib.mkIf homelab.services.enableReverseProxy {
      "http://${homelab.hostname}:${toString cfg.port}" = {
        extraConfig = ''
          reverse_proxy unix//run/gitlab/gitlab-workhorse.socket
        '';
      };
    };

    # Open firewall for GitLab access on local network
    networking.firewall.allowedTCPPorts = [cfg.port];
  };
}
