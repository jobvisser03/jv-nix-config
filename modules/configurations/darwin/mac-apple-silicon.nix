# Work MacBook (Apple Silicon) - Darwin configuration
{
  inputs,
  config,
  lib,
  ...
}: {
  flake.darwinConfigurations.mac-apple-silicon-host = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = {
      inherit inputs;
      username = config.my.users.work.username;
    };
    modules = [
      # Our deferred modules
      config.flake.modules.darwin.common
      config.flake.modules.darwin.homebrew

      # Host-specific configuration
      ({
        pkgs,
        username,
        ...
      }: {
        users.users.${username} = {
          home = "/Users/${username}";
        };
        system.primaryUser = username;

        # macOS Sequoia compatibility
        ids.uids.nixbld = 31000;

        # Apple Silicon architecture
        nixpkgs.hostPlatform = "aarch64-darwin";
      })
    ];
  };
}
