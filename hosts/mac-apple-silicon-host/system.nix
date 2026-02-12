# Nix-darwin system configuration for managing macos settings
{username, ...}: {
  # This is needed for home-manager to work
  users.users.${username} = {home = "/Users/${username}";};
  system.primaryUser = username;

  # this is needed for nix-darwin to work with macos Sequoia
  ids.uids.nixbld = 31000;

  # hostplatform is just macbook for now
  nixpkgs.hostPlatform = "aarch64-darwin";
}
