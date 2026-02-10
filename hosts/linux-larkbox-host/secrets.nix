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
      # Note: All secrets use root:root ownership because users may not exist during early boot
      # Mode 0444 (world-readable) is safe because /run/secrets directory itself has restricted permissions
      gitlab_database_password = {
        mode = "0444";
      };

      # GitLab initial root password
      gitlab_initial_root_password = {
        mode = "0444";
      };

      # GitLab secret key base
      gitlab_secret = {
        mode = "0444";
      };

      # GitLab OTP secret
      gitlab_otp_secret = {
        mode = "0444";
      };

      # GitLab database secret
      gitlab_db_secret = {
        mode = "0444";
      };

      # GitLab JWS private key
      gitlab_jws_key = {
        mode = "0444";
      };

      # GitLab Active Record encryption keys
      gitlab_active_record_primary_key = {
        mode = "0444";
      };

      gitlab_active_record_deterministic_key = {
        mode = "0444";
      };

      gitlab_active_record_salt = {
        mode = "0444";
      };

      # GitLab Runner registration config
      # Contains CI_SERVER_URL and CI_SERVER_TOKEN (runner authentication token)
      # Get token from GitLab: Admin > CI/CD > Runners > New instance runner
      gitlab_runner_registration = {
        mode = "0444";
      };

      # Paperless-ngx admin password
      # Used as the initial admin user password
      paperless_admin_password = {
        mode = "0444";
      };
    };
  };
}
