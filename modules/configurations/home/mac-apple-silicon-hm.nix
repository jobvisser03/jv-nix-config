# Standalone home-manager for work MacBook (Apple Silicon)
{
  inputs,
  config,
  lib,
  ...
}: {
  flake.homeConfigurations.mac-apple-silicon-hm = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
    extraSpecialArgs = {inherit inputs;};
    modules = [
      config.flake.modules.home.common
      config.flake.modules.home.packages
      config.flake.modules.home.zsh
      config.flake.modules.home.shell-tools
      config.flake.modules.home.dev-tools
      config.flake.modules.home.browser
      config.flake.modules.home.darwin

      {
        home.username = config.my.users.work.username;
        home.homeDirectory = config.my.users.work.homeDirectory.darwin;
      }
    ];
  };
}
