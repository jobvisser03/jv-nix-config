# Direnv configuration
# Home-manager only module
{...}: {
  flake.modules.homeManager.direnv = {
    pkgs,
    lib,
    config,
    ...
  }: {
    programs.direnv = {
      enable = true;
      silent = true;
      config = {
        global.load_dotenv = true;
      };
    };
  };
}
