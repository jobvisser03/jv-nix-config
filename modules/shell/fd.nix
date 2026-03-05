# fd (find replacement) configuration
# Home-manager only module
{...}: {
  flake.modules.homeManager.fd = {
    pkgs,
    lib,
    config,
    ...
  }: {
    programs.fd = {
      enable = true;
      extraOptions = [
        "--no-ignore"
        "--absolute-path"
      ];
      ignores = [
        ".git"
        ".hg"
      ];
    };
  };
}
