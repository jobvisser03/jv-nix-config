{
  pkgs,
  lib,
  ...
}: {
  programs = {
    atuin = {
      enable = true;
      settings = {
        style = "compact";
        enter_accept = true;
        filter_mode_shell_up_key_binding = "directory";
        search_mode_shell_up_key_binding = "prefix";
        show_preview = false;
        show_tabs = false;
        ctrl_n_shortcuts = true;
        sync = {
          records = false;
        };
        auto_sync = false;
      };
    };

    direnv = {
      enable = true;
      silent = true;
      config = {
        global.load_dotenv = true;
      };
    };

    eza = {
      enable = true;
      git = true;
      icons = "auto";
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
    };

    fd = {
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

    zsh = {
      enable = true;
      autocd = true;
      syntaxHighlighting.enable = true;
      autosuggestion.enable = true;
      history = {
        append = true;
        ignoreDups = true;
        ignoreAllDups = true;
        ignoreSpace = false;
      };
      initContent = lib.mkAfter ''
        export PATH="$HOME/.cargo/bin:$PATH"
        export PATH="$HOME/repos/experiments/flutter/bin:$PATH"
        export GEM_HOME=$HOME/.gem
        export PATH=$GEM_HOME/bin:$PATH
        export PATH="$HOME/.gem/ruby/3.3.0/bin:$PATH"
        export PATH="$HOME/.local/bin:$PATH"
        export PATH="$HOME/.rd/bin:$PATH"

        export PIP_REQUIRE_VIRTUALENV=1
        export PIP_USE_PEP517=1
        export MANPAGER="sh -c 'col -bx | bat -l man -p'"
        export LANG="en_US.UTF-8"
        export LC_CTYPE="en_US.UTF-8"
        export LC_ALL="en_US.UTF-8"
        export LANGUAGE="en_US.UTF-8"

        # Only set up atuin autosuggestions if atuin is available
        if command -v atuin &> /dev/null; then
            _zsh_autosuggest_strategy_atuin_auto() {
                suggestion=$(atuin search --cwd . --cmd-only --limit 1 --search-mode prefix -- "$1")
            }

            _zsh_autosuggest_strategy_atuin_global() {
                suggestion=$(atuin search --cmd-only --limit 1 --search-mode prefix -- "$1")
            }
            export ZSH_AUTOSUGGEST_STRATEGY=(atuin_auto atuin_global)
        fi

        pip() {
            if ! type -P pip &> /dev/null
            then
                uv pip "$@"
            else
                command pip "$@"
            fi
        }

        bindkey "^ " autosuggest-accept
        test -e "$HOME/.iterm2_shell_integration.zsh" && source "$HOME/.iterm2_shell_integration.zsh"
      '';

      shellAliases = import ../alias.nix;

      plugins = [
        {
          name = "fzf-tab";
          src = pkgs.fetchFromGitHub {
            owner = "Aloxaf";
            repo = "fzf-tab";
            rev = "c2b4aa5ad2532cca91f23908ac7f00efb7ff09c9";
            sha256 = "1b4pksrc573aklk71dn2zikiymsvq19bgvamrdffpf7azpq6kxl2";
          };
        }
      ];
    };
  };
}
