# Git configuration
# Home-manager only module
{...}: {
  flake.modules.homeManager.git = {
    pkgs,
    lib,
    config,
    ...
  }: {
    programs.git = {
      enable = true;
      lfs.enable = true;

      settings = {
        user = {
          name = "Job Visser";
          email = "job@dutchdataworks.com";
        };
        init.defaultBranch = "main";
        rerere.enabled = true;
        pull.rebase = true;
        push.autoSetupRemote = true;
        pack.sparse = true;
        core.editor = "code --wait";
      };

      ignores = [
        ".DS_Store"
        "temp.ipynb"
        "my_local_files/"
      ];
    };
  };
}
