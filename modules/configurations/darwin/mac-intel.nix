# Personal Intel Mac - Darwin configuration
{
  inputs,
  config,
  lib,
  ...
}: {
  flake.darwinConfigurations.mac-intel-host = inputs.darwin.lib.darwinSystem {
    system = "x86_64-darwin";
    specialArgs = {
      inherit inputs;
      username = config.my.users.personal.username;
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

        # Intel processor architecture
        nixpkgs.hostPlatform = "x86_64-darwin";
      })
    ];
  };
}
