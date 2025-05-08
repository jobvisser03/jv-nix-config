# Nix-darwin system configuration for managing macos settings
{
  ...
}: {
  # This is needed for home-manager to work
  users.users.job = {home = "/Users/job";};

  # intel processor architecture
  nixpkgs.hostPlatform = "x86_64-darwin";
}
