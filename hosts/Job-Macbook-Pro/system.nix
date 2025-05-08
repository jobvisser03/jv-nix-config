# Nix-darwin system configuration for managing macos settings, we don't use this now
{
  ...
}: {
  # This is needed for home-manager to work
  users.users.job = {home = "/Users/job";};

  # hostplatform is just macbook for now
  nixpkgs.hostPlatform = "x86_64-darwin";
}
