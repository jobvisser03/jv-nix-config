# Larkbox secrets configuration
# Defines which secrets this host needs and their permissions.
#
# The actual secret values are stored encrypted in ../../secrets/larkbox.yaml
# Edit secrets with: sops secrets/larkbox.yaml
{config, ...}: {
  sops = {
    # Use larkbox-specific secrets file
    defaultSopsFile = ../../secrets/larkbox.yaml;

    secrets = {
      # Radicale CalDAV/CardDAV authentication
      # Format: htpasswd format (username:password_hash)
      # Generate with: htpasswd -nb username password
      # radicale_htpasswd = {
      #   owner = "radicale";
      #   group = "radicale";
      #   mode = "0400";
      # };

      # Jellyfin API key for homepage widget integration (disabled)
      # Get from Jellyfin: Dashboard > API Keys > Add
      # jellyfin_api_key = {
      #   owner = config.homelab.user;
      #   group = config.homelab.group;
      #   mode = "0400";
      # };

      # Rclone configuration file (contains pCloud OAuth token)
      # Generate with: rclone config
      # Then copy ~/.config/rclone/rclone.conf content to sops
      rclone_config = {
        owner = "root";
        group = "root";
        mode = "0400";
        path = "/run/secrets/rclone.conf";
      };

      # GitLab database password
      gitlab_database_password = {
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };

      # GitLab initial root password
      gitlab_initial_root_password = {
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };

      # GitLab secret key base
      gitlab_secret = {
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };

      # GitLab OTP secret
      gitlab_otp_secret = {
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };

      # GitLab database secret
      gitlab_db_secret = {
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };

      # GitLab JWS private key
      gitlab_jws_key = {
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };

      # GitLab Active Record encryption keys
      gitlab_active_record_primary_key = {
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };

      gitlab_active_record_deterministic_key = {
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };

      gitlab_active_record_salt = {
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };

      # GitLab Runner registration config
      # Contains CI_SERVER_URL and CI_SERVER_TOKEN (runner authentication token)
      # Get token from GitLab: Admin > CI/CD > Runners > New instance runner
      # Note: Owner is root because gitlab-runner uses DynamicUser and the
      # configure script runs as root (ExecStartPre with ! prefix)
      gitlab_runner_registration = {
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };
  };
}
