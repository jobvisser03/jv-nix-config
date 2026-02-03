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
    };
  };
}
