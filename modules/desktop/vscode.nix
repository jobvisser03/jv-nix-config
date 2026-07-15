# Declarative Visual Studio Code configuration shared by Linux and Darwin.
{...}: {
  flake.modules = {
    nixos.vscode = {inputs, ...}: {
      nixpkgs.overlays = [inputs.nix4vscode.overlays.default];
    };

    darwin.vscode = {inputs, ...}: {
      nixpkgs.overlays = [inputs.nix4vscode.overlays.default];
    };

    homeManager.vscode = {pkgs, ...}: {
      programs.vscode = {
        enable = true;
        package =
          if pkgs.stdenv.hostPlatform.isDarwin
          then null
          else pkgs.vscode.fhs;
        mutableExtensionsDir = false;

        profiles.default = {
          enableUpdateCheck = false;
          enableExtensionUpdateCheck = false;

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

          userSettings = {
            "git.autofetch" = true;
            "git.enableSmartCommit" = true;
            "git.confirmSync" = false;
            "diffEditor.ignoreTrimWhitespace" = false;
            "editor.formatOnSave" = true;
            "editor.minimap.enabled" = false;
            "explorer.confirmDelete" = false;
            "explorer.confirmDragAndDrop" = false;
            "explorer.confirmPasteNative" = false;
            "security.workspace.trust.untrustedFiles" = "open";
            "terminal.integrated.fontFamily" = "CaskaydiaCove Nerd Font, MesloLGS NF, Inconsolata-g for Powerline, Source Code Pro for Powerline";
            "terminal.integrated.suggest.enabled" = false;
            "workbench.colorTheme" = "Cobalt2";

            "chat.instructionsFilesLocations" = {
              ".github/instructions" = true;
            };
            "chat.viewSessions.orientation" = "stacked";
            "claudeCode.preferredLocation" = "panel";
            "claudeCode.selectedModel" = "opus";
            "docker.extension.enableComposeLanguageServer" = false;
            "github.copilot.enable" = {
              "*" = true;
              plaintext = false;
              markdown = true;
              scminput = false;
            };
            "github.copilot.nextEditSuggestions.enabled" = true;
            "gitlens.ai.model" = "vscode";
            "jupyter.askForKernelRestart" = false;
            "nix.formatterPath" = "alejandra";
            "dbcode.ai.inlineCompletion" = false;
            "vim.easymotion" = true;
            "vim.useSystemClipboard" = true;
            "vim.cursorStylePerMode.insert" = "line";
            "vim.cursorStylePerMode.normal" = "block";
            "vim.insertModeKeyBindings" = [
              {
                before = ["j" "j"];
                after = ["<Esc>"];
              }
              {
                before = ["f" "d"];
                after = ["<Esc>"];
              }
            ];
            "vim.normalModeKeyBindingsNonRecursive" = [
              {
                before = ["<space>"];
                commands = ["vspacecode.space"];
              }
              {
                before = [","];
                commands = [
                  "vspacecode.space"
                  {
                    command = "whichkey.triggerKey";
                    args = "m";
                  }
                ];
              }
            ];
            "vim.visualModeKeyBindingsNonRecursive" = [
              {
                before = ["<space>"];
                commands = ["vspacecode.space"];
              }
              {
                before = [","];
                commands = [
                  "vspacecode.space"
                  {
                    command = "whichkey.triggerKey";
                    args = "m";
                  }
                ];
              }
              {
                before = [">"];
                commands = ["editor.action.indentLines"];
              }
              {
                before = ["<"];
                commands = ["editor.action.outdentLines"];
              }
            ];
          };

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
