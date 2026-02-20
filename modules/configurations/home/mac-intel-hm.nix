# Standalone home-manager for personal Intel Mac
{
  inputs,
  config,
  lib,
  ...
}: {
  flake.homeConfigurations.mac-intel-hm = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-darwin;
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
        home.username = config.my.users.personal.username;
        home.homeDirectory = config.my.users.personal.homeDirectory.darwin;
      }
    ];
  };
}
