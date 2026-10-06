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

    # Keep Obsidian on the same Syncthing folder used by Framework and Larkbox.
    home-manager.users.${username}.programs.obsidian.vaults.notes.target =
      lib.mkForce "syncthing/obsidian_vault";

    # Apple Silicon processor architecture
    nixpkgs.hostPlatform = "aarch64-darwin";
  };
}
