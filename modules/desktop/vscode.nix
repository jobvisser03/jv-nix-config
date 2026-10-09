# Declarative Visual Studio Code configuration shared by Linux and Darwin.
{...}: {
  flake.modules = {
    nixos.vscode = {inputs, ...}: {
      nixpkgs.overlays = [inputs.nix4vscode.overlays.default];
    };

    darwin.vscode = {inputs, ...}: {
      nixpkgs.overlays = [inputs.nix4vscode.overlays.default];
    };

    homeManager.vscode = {
      pkgs,
      config,
      ...
    }: let
      # Must match the path home-manager's vscode module uses for the default profile.
      settingsPath =
        if pkgs.stdenv.hostPlatform.isDarwin
        then "${config.home.homeDirectory}/Library/Application Support/Code/User/settings.json"
        else "${config.xdg.configHome}/Code/User/settings.json";
    in {
      # settings.json is a symlink to vscode-settings.json in this repo instead of
      # home-manager's `userSettings`, which puts the file in the read-only Nix store.
      # VS Code and its extensions (Claude Code, GitLens, Copilot, vim, …) write to
      # settings.json whenever a setting changes, and a store file makes every such
      # write fail with EROFS ("Failed to save 'settings.json'"). Linking out of the
      # store keeps it writable; whatever VS Code changes shows up in `git diff` to
      # commit or revert. The update-check flags (`update.mode`,
      # `extensions.autoCheckUpdates`) live in the JSON too, because
      # enableUpdateCheck/enableExtensionUpdateCheck would make home-manager generate
      # its own settings.json again.
      # Assumes the repo is checked out at ~/repos/jv-nix-config on every host.
      home.file.${settingsPath}.source =
        config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/repos/jv-nix-config/modules/desktop/vscode-settings.json";

      programs.vscode = {
        enable = true;
        package =
          if pkgs.stdenv.hostPlatform.isDarwin
          then null
          else pkgs.vscode.fhs;
        mutableExtensionsDir = false;

        profiles.default = {
          extensions = pkgs.nix4vscode.forVscode [
            "antfu.slidev"
            "1yib.svelte-bundle"
            "svelte.svelte-vscode"
            "ardenivanov.svelte-intellisense"
            "bradlc.vscode-tailwindcss"
            "charliermarsh.ruff"
            "dbcode.dbcode"
            "docker.docker"
            "eamodio.gitlens"
            "github.remotehub"
            "hashicorp.terraform"
            "jacobdufault.fuzzy-search"
            "jellydn.vscode-hurl-runner"
            "jnoortheen.nix-ide"
            "cometeer.spacemacs"
            "wesbos.theme-cobalt2"
            "ms-azuretools.vscode-azure-github-copilot"
            "ms-azuretools.vscode-azure-mcp-server"
            "ms-azuretools.vscode-containers"
            "ms-azuretools.vscode-docker"
            "ms-python.debugpy"
            "ms-python.python"
            "ms-python.vscode-pylance"
            "ms-python.vscode-python-envs"
            "ms-toolsai.datawrangler"
            "ms-toolsai.jupyter"
            "ms-toolsai.jupyter-renderers"
            "ms-toolsai.vscode-ai"
            "ms-toolsai.vscode-ai-remote"
            "ms-toolsai.vscode-jupyter-cell-tags"
            "ms-toolsai.vscode-jupyter-slideshow"
            "ms-vscode-remote.remote-containers"
            "ms-vscode-remote.remote-ssh"
            "ms-vscode-remote.remote-ssh-edit"
            "pkief.material-icon-theme"
            "redhat.vscode-yaml"
            "tamasfe.even-better-toml"
            "vscodevim.vim"
            "vspacecode.vspacecode"
            "vspacecode.whichkey"
            "kahole.magit"
            "yzhang.markdown-all-in-one"
          ];

          keybindings =
            (builtins.fromJSON (builtins.readFile ./vscode-vspacecode-keybindings.json))
            ++ [
              {
                key = "cmd+t";
                command = "-workbench.action.showAllSymbols";
              }
              {
                key = "cmd+t";
                command = "workbench.action.terminal.focus";
              }
              {
                key = "ctrl+alt+cmd+right";
                command = "editor.action.smartSelect.grow";
              }
              {
                key = "alt+tab";
                command = "workbench.action.quickOpenPreviousRecentlyUsedEditorInGroup";
              }
              {
                key = "ctrl+tab";
                command = "-workbench.action.quickOpenPreviousRecentlyUsedEditorInGroup";
              }
              {
                key = "alt+tab";
                command = "workbench.action.quickOpenNavigateNextInEditorPicker";
                when = "inEditorsPicker && inQuickOpen";
              }
              {
                key = "ctrl+tab";
                command = "-workbench.action.quickOpenNavigateNextInEditorPicker";
                when = "inEditorsPicker && inQuickOpen";
              }
              {
                key = "shift+alt+tab";
                command = "workbench.action.quickOpenLeastRecentlyUsedEditorInGroup";
              }
              {
                key = "ctrl+shift+tab";
                command = "-workbench.action.quickOpenLeastRecentlyUsedEditorInGroup";
              }
              {
                key = "shift+alt+tab";
                command = "workbench.action.quickOpenNavigatePreviousInEditorPicker";
                when = "inEditorsPicker && inQuickOpen";
              }
              {
                key = "ctrl+shift+tab";
                command = "-workbench.action.quickOpenNavigatePreviousInEditorPicker";
                when = "inEditorsPicker && inQuickOpen";
              }
              {
                key = "ctrl+shift+n";
                command = "jupyter.addcellbelow";
              }
              {
                key = "down";
                command = "-selectNextSuggestion";
                when = "suggestWidgetMultipleSuggestions && suggestWidgetVisible && textInputFocus";
              }
              {
                key = "ctrl+tab";
                command = "selectPrevSuggestion";
                when = "suggestWidgetMultipleSuggestions && suggestWidgetVisible && textInputFocus";
              }
              {
                key = "up";
                command = "-selectPrevSuggestion";
                when = "suggestWidgetMultipleSuggestions && suggestWidgetVisible && textInputFocus";
              }
            ];
        };
      };
    };
  };
}
