# Nix-darwin system configuration for managing macos settings
{username, ...}: {
  # This is needed for home-manager to work
  users.users.${username} = {home = "/Users/${username}";};
  system.primaryUser = username;

  # intel processor architecture
  nixpkgs.hostPlatform = "x86_64-darwin";
}
