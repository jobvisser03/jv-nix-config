{...}: {
  programs = {
    awscli.enable = true;
    bat.enable = true;
    broot.enable = true;
    btop.enable = true;

    git = {
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

    jq.enable = true;

    ripgrep = {
      enable = true;
      arguments = [
        "--max-columns=150"
        "--max-columns-preview"
        "--hidden"
        "--glob=!.git/*"
        "--smart-case"
      ];
    };

    tealdeer = {
      enable = true;
      settings.updates.auto_update = true;
    };

    zoxide.enable = true;
  };
}
