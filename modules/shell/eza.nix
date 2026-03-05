# Eza (modern ls replacement) configuration
# Home-manager only module
{...}: {
  flake.modules.homeManager.eza = {
    pkgs,
    lib,
    config,
    ...
  }: {
    programs.eza = {
      enable = true;
      git = true;
      icons = "auto";
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
    };
  };
}
