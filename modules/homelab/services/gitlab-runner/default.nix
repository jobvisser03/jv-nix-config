# GitLab Runner - CI/CD job executor for GitLab
# https://wiki.nixos.org/wiki/Gitlab_runner
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.gitlab-runner;
in {
  options.homelab.services.gitlab-runner = {
    enable = lib.mkEnableOption "GitLab Runner - CI/CD job executor";

    # Registration configuration
    gitlabUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://${config.homelab.hostname}:${toString config.homelab.services.gitlab.port}";
      description = "URL of the GitLab instance";
    };

    # Secret file containing authentication token (new GitLab 17+ workflow)
    authenticationTokenConfigFile = lib.mkOption {
      type = lib.types.path;
      default = config.sops.secrets.gitlab_runner_registration.path;
      description = ''
        Path to file containing the runner authentication token.
        Should contain: CI_SERVER_TOKEN=glrt-xxxxxxxxxxxxxxxxxxxx
        
        Get token from GitLab: Admin > CI/CD > Runners > New instance runner
        Configure tags, protected status, etc. in GitLab UI when creating the runner.
      '';
    };

    # Docker configuration
    dockerImage = lib.mkOption {
      type = lib.types.str;
      default = "alpine:latest";
      description = "Default Docker image for CI jobs";
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
    # Enable IP forwarding for container networking
    boot.kernel.sysctl."net.ipv4.ip_forward" = true;

    # Enable Podman's Docker-compatible socket for gitlab-runner
    # This allows gitlab-runner to use Podman as the container runtime
    virtualisation.podman.dockerSocket.enable = true;

    # Prevent gitlab-runner module from auto-enabling Docker
    # We use Podman with dockerSocket instead
    virtualisation.docker.enable = lib.mkForce false;

    # Create a combined auth config file that includes both URL and token
    # The token file from sops contains only CI_SERVER_TOKEN
    # We need to add CI_SERVER_URL for the registration to work
    systemd.services.gitlab-runner-auth-config = {
      description = "Generate GitLab Runner authentication config";
      wantedBy = ["gitlab-runner.service"];
      before = ["gitlab-runner.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mkdir -p /run/gitlab-runner
        {
          echo "CI_SERVER_URL=${cfg.gitlabUrl}"
          cat ${cfg.authenticationTokenConfigFile}
        } > /run/gitlab-runner/auth-config
        chmod 600 /run/gitlab-runner/auth-config
      '';
    };

    # GitLab Runner service
    services.gitlab-runner = {
      enable = true;
      settings.concurrent = cfg.concurrent;

      services = {
        # Nix-enabled runner using Docker executor with host's nix-daemon
        # This shares the host's nix store with containers for caching
        # Uses Podman via Docker-compatible socket
        # Note: Tags, protected status, etc. are configured in GitLab UI (new workflow)
        nix = {
          authenticationTokenConfigFile = "/run/gitlab-runner/auth-config";
          executor = "docker";
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
        };
      };
    };
  };
}
