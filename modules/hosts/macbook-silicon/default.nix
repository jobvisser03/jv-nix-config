# MacBook Apple Silicon running macOS (Darwin) host definition
# Work machine with job.visser user
{...}: {
  flake.modules.darwin."hosts/macbook-silicon" = {
    pkgs,
    lib,
    config,
    username,
    ...
  }: {
    # User configuration for home-manager
    users.users.${username} = {
      home = "/Users/${username}";
    };
    system.primaryUser = username;

    # Apple Silicon processor architecture
    nixpkgs.hostPlatform = "aarch64-darwin";
  };
}
