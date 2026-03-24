# MacBook Intel running macOS (Darwin) host definition
{...}: {
  flake.modules.darwin."hosts/macbook-intel" = {
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

    # Intel processor architecture
    nixpkgs.hostPlatform = "x86_64-darwin";
  };
}
