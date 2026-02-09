# GitLab Runner - CI/CD job executor for GitLab
# https://wiki.nixos.org/wiki/Gitlab_runner
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.gitlab-runner;
  homelab = config.homelab;
in {
  options.homelab.services.gitlab-runner = {
    enable = lib.mkEnableOption "GitLab Runner - CI/CD job executor";

    # Registration configuration
    gitlabUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://gitlab.com";
      description = "URL of the GitLab instance";
    };

    # Secret file containing CI_SERVER_URL and REGISTRATION_TOKEN (or CI_SERVER_TOKEN for new registration)
    registrationConfigFile = lib.mkOption {
      type = lib.types.path;
      default = config.sops.secrets.gitlab_runner_registration.path;
      description = ''
        Path to environment file containing registration variables.
        Should contain at minimum:
        - CI_SERVER_URL=https://gitlab.com (or your GitLab instance URL)
        - CI_SERVER_TOKEN=<runner-authentication-token>
      '';
    };

    # Docker configuration
    dockerImage = lib.mkOption {
      type = lib.types.str;
      default = "alpine:latest";
      description = "Default Docker image for CI jobs";
    };

    # Runner tags
    tagList = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["nix" "docker"];
      description = "Tags for the runner to pick up specific jobs";
    };

    # Concurrent jobs
    concurrent = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Maximum number of concurrent jobs";
    };

    # Homepage dashboard integration
    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "GitLab Runner";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "CI/CD job executor for GitLab";
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
    # Enable IP forwarding for Docker networking
    boot.kernel.sysctl."net.ipv4.ip_forward" = true;

    # Enable Docker for the runner
    virtualisation.docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    # GitLab Runner service
    services.gitlab-runner = {
      enable = true;
      settings.concurrent = cfg.concurrent;

      services = {
        # Nix-enabled runner using Docker executor with host's nix-daemon
        # This shares the host's nix store with containers for caching
        nix = {
          registrationConfigFile = cfg.registrationConfigFile;
          dockerImage = cfg.dockerImage;
          dockerVolumes = [
            "/nix/store:/nix/store:ro"
            "/nix/var/nix/db:/nix/var/nix/db:ro"
            "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
          ];
          dockerDisableCache = true;
          preBuildScript = pkgs.writeScript "setup-nix-container" ''
            mkdir -p -m 0755 /nix/var/log/nix/drvs
            mkdir -p -m 0755 /nix/var/nix/gcroots
            mkdir -p -m 0755 /nix/var/nix/profiles
            mkdir -p -m 0755 /nix/var/nix/temproots
            mkdir -p -m 0755 /nix/var/nix/userpool
            mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
            mkdir -p -m 1777 /nix/var/nix/profiles/per-user
            mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root
            mkdir -p -m 0700 "$HOME/.nix-defexpr"
            . ${pkgs.nix}/etc/profile.d/nix-daemon.sh
            ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs
            ${pkgs.nix}/bin/nix-channel --update nixpkgs
            ${pkgs.nix}/bin/nix-env -i ${lib.concatStringsSep " " (with pkgs; [nix cacert git openssh])}
          '';
          environmentVariables = {
            ENV = "/etc/profile";
            USER = "root";
            NIX_REMOTE = "daemon";
            PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
            NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
          };
          tagList = cfg.tagList;
        };
      };
    };
  };
}
