{
  pkgs,
  lib,
  config,
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

    oh-my-posh = {
      enable = true;
      # useTheme = "catppuccin_mocha";
      enableZshIntegration = true;
      settings = {
        "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
        version = 2;
        console_title_template = "{{.Folder}}{{if .Root}}::root{{end}}::{{.Shell}}";
        blocks = [
          {
            type = "prompt";
            newline = true;
            alignment = "left";
            segments = [
              {
                type = "path";
                properties = {
                  # style = "unique";
                  style = "powerlevel";
                  max_width = 50;
                };
                template = "{{- .Path -}}";
              }
              {
                type = "git";
                style = "plain";
              }
              {
                type = "root";
                style = "plain";
                foreground = "red";
                template = "❄️";
              }
            ];
          }
          {
            type = "prompt";
            newline = true;
            alignment = "left";
            segments = [
              {
                type = "text";
                style = "plain";
                foreground_templates = [
                  "{{if gt .Code 0}}red{{end}}"
                  "{{if eq .Code 0}}blue{{end}}"
                ];
                template = " ";
              }
            ];
          }
          {
            type = "rprompt";
            # alignment = "right";
            segments = [
              # {
              #   template = "❄️ nix-{{ .Type }}";
              #   type = "nix-shell";
              # }
              {
                type = "session";
                style = "plain";
                template = "{{ if .SSHSession }} {{ end }}  {{ .HostName }}";
              }
              {
                type = "python";
                style = "plain";
                foreground = "#ffd43b";
                background = "#306998";
                template = "  {{ .Full }} ";
              }
              {
                type = "executiontime";
                style = "plain";
                foreground = "yellow";
                properties = {
                  threshold = 5000;
                  style = "round";
                };
                template = "  {{ .FormattedMs }}";
              }
            ];
          }
        ];
        secondary_prompt = {
          foreground_templates = [
            "{{if gt .Code 0}}red{{end}}"
            "{{if eq .Code 0}}blue{{end}}"
          ];
          template = " ";
        };
        transient_prompt = {
          foreground_templates = [
            "{{if gt .Code 0}}red{{end}}"
            "{{if eq .Code 0}}blue{{end}}"
          ];
          template = " ";
        };
      };
    };
    # settings = {
    #   final_space = true;
    #   shell_integration = true;
    #   enable_cursor_positioning = true;
    #   iterm_features = [
    #     "remote_host"
    #     "current_dir"
    #   ];
    # blocks = [
    #   {
    #     alignment = "left";
    #     segments = [
    #       {
    #         background = "#d3d7cf";
    #         foreground = "#000000";
    #         style = "diamond";
    #         template = " {{ if .WSL }}WSL at {{ end }}{{.Icon}} ";
    #         type = "os";
    #       }
    #       {
    #         background = "#6c6c6c";
    #         foreground = "#ffffff";
    #         powerline_symbol = builtins.fromJSON ''"\ue0b0"'';
    #         style = "powerline";
    #         template = " {{ .HostName }} ";
    #         type = "session";
    #       }
    #       {
    #         background = "#3465a4";
    #         foreground = "#e4e4e4";
    #         powerline_symbol = builtins.fromJSON ''"\ue0b0"'';
    #         properties = {
    #           home_icon = "~";
    #           style = "full";
    #         };
    #         style = "powerline";
    #         template = builtins.fromJSON ''" \uf07c {{ .Path }} "'';
    #         type = "path";
    #       }
    #       {
    #         background = "#4e9a06";
    #         background_templates = [
    #           "{{ if or (.Working.Changed) (.Staging.Changed) }}#c4a000{{ end }}"
    #           "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#f26d50{{ end }}"
    #           "{{ if gt .Ahead 0 }}#89d1dc{{ end }}"
    #           "{{ if gt .Behind 0 }}#4e9a06{{ end }}"
    #         ];
    #         foreground = "#000000";
    #         powerline_symbol = builtins.fromJSON ''"\ue0b0"'';
    #         properties = {
    #           branch_icon = builtins.fromJSON ''"\uf126 "'';
    #           fetch_stash_count = true;
    #           fetch_status = true;
    #           fetch_upstream_icon = true;
    #         };
    #         style = "powerline";
    #         template = builtins.fromJSON ''" {{ .UpstreamIcon }}{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }} \uf046 {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }} \ueb4b {{ .StashCount }}{{ end }} "'';
    #         type = "git";
    #       }
    #     ];
    #     type = "prompt";
    #   }
    #   {
    #     alignment = "left";
    #     newline = true;
    #     segments = [
    #       {
    #         foreground = "#81ff91";
    #         foreground_templates = ["{{if gt .Code 0}}#ff3030{{end}}"];
    #         style = "diamond";
    #         template = builtins.fromJSON ''"\u276f"'';
    #         properties.always_enabled = true;
    #         type = "text";
    #       }
    #     ];
    #     type = "prompt";
    #   }
    # ];
    #   version = 3;
    #   console_title_template = "{{ .Shell }} in {{ .Folder }}";
    # };
    # };

    pandoc.enable = true;

    kitty.enable = true;

    wezterm = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      extraConfig = builtins.readFile ../../non-nix-configs/wezterm.lua;
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
