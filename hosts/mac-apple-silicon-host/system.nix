# Nix-darwin system configuration for managing macos settings
{
  ...
}: {
  # This is needed for home-manager to work
  users.users.job = {home = "/Users/job.visser";};

  # this is needed for nix-darwin to work with macos Sequoia
  ids.uids.nixbld = 31000;

 # hostplatform is just macbook for now
  nixpkgs.hostPlatform = "aarch64-darwin";
}
