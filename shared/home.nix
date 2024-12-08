{
  pkgs,
  lib,
  ...
}: {
  home.username = "simon";

  programs = {
    awscli.enable = true;
    atuin = {
      enable = true;
      settings = {
        sync_frequency = "5m";
        style = "compact";
        enter_accept = true;
        filter_mode_shell_up_key_binding = "session";
        sync = {
          records = true;
        };
      };
    };
    bat.enable = true;
    broot.enable = true;
    btop.enable = true;
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
    # fzf = {
    #   enable = true;
    #   fileWidgetCommand = "fd --type file --follow --hidden --exclude .git";
    # };
    git = {
      enable = true;
      lfs.enable = true;

      userName = "Simon Riezebos";
      userEmail = "info@datagiant.org";
      extraConfig = {
        init.defaultBranch = "main";
        rerere.enabled = true;
        pull.rebase = true;
        push.autoSetupRemote = true;
        pack.sparse = true;
        core.editor = "cursor --wait";
      };
      ignores = [
        ".DS_Store"
        "temp.ipynb"
        "my_local_files/"
      ];
      includes = [
        {
          path = "~/repos/volt/.gitconfig";
          condition = "gitdir:~/repos/volt/";
        }
      ];
    };
    jq.enable = true;
    starship = {
      enable = true;
      settings = {
        command_timeout = 10000;
        add_newline = false;

        format = lib.strings.concatStrings [
          "$hostname"
          "[](#DA627D)"
          "$directory"
          "[](fg:#DA627D bg:#FCA17D)"
          "$git_branch"
          "$git_status"
          "[](fg:#FCA17D bg:#86BBD8)"
          "$python"
          "$conda"
          "$terraform"
          "$c"
          "$elixir"
          "$elm"
          "$golang"
          "$gradle"
          "$haskell"
          "$java"
          "$julia"
          "$nodejs"
          "$nim"
          "$rust"
          "$scala"
          "[](fg:#86BBD8 bg:#06969A)"
          "$cmd_duration"
          "[](#06969A)"
        ];
        # line_break.disabled = true;

        aws.disabled = true;
        gcloud.disabled = true;

        cmd_duration.format = "[⏲ $duration]($style)";
        cmd_duration.style = "bg:#06969a";

        username = {
          show_always = false;
          style_user = "bg:#9a348e";
          style_root = "bg:#9a348e";
          format = "[ $user ]($style)";
          disabled = true;
        };

        directory = {
          style = "bg:#DA627D";
          format = "[ $path ]($style)";
          substitutions = {
            "Documents" = "󰈙 ";
            "Downloads" = " ";
            "Music" = " ";
            "Pictures" = " ";
          };
        };

        c = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[$symbol($version) ]($style)";
        };

        docker_context = {
          symbol = " ";
          style = "bg:#06969A";
          format = "[ $symbol $context ]($style) $path";
        };

        elixir = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[$symbol($version) ]($style)";
        };

        elm = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[$symbol($version) ]($style)";
        };

        git_branch = {
          symbol = " ";
          style = "bg:#FCA17D";
          format = "[$symbol$branch ]($style)";
        };

        git_status = {
          style = "bg:#FCA17D";
          format = "[$all_status$ahead_behind]($style)";
          ahead = "⇡$count";
          diverged = "⇡$ahead_count⇣$behind_count";
          behind = "⇣$count";
          conflicted = "≠";
          up_to_date = "✓";
          untracked = "…";
          stashed = "⚑";
          modified = "+";
        };

        golang = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[$symbol($version) ]($style)";
        };

        gradle = {
          style = "bg:#86BBD8";
          format = "[$symbol($version) ]($style)";
        };

        haskell = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[$symbol($version) ]($style)";
        };

        hostname = {
          format = "[$ssh_symbol$hostname ]($style)";
        };

        java = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[$symbol($version) ]($style)";
        };

        julia = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[$symbol($version) ]($style)";
        };

        python = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[$symbol$pyenv_prefix($version) ($virtualenv)]($style)";
        };

        nodejs = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[$symbol($version)]($style)";
        };

        nim = {
          symbol = "󰆥 ";
          style = "bg:#86BBD8";
          format = "[$symbol($version) ]($style)";
        };

        rust = {
          symbol = "";
          style = "bg:#86BBD8";
          format = "[$symbol($version) ]($style)";
        };

        scala = {
          symbol = " ";
          style = "bg:#86BBD8";
          format = "[$symbol($version) ]($style)";
        };

        time = {
          disabled = false;
          time_format = "%R";
          style = "bg:#33658A";
          format = "[ ♥ $time ]($style)";
        };
      };
    };
    pandoc.enable = true;
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
    tealdeer.enable = true;
    yt-dlp.enable = true;
    zoxide.enable = true;
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
      initExtra = ''
        export PATH="$HOME/.cargo/bin:$PATH"
        export PATH="$HOME/repos/experiments/flutter/bin:$PATH"
        export GEM_HOME=$HOME/.gem
        export PATH=$GEM_HOME/bin:$PATH
        export PATH="$HOME/.gem/ruby/3.3.0/bin:$PATH"
        export PATH="$HOME/.local/bin:$PATH"

        export PIP_REQUIRE_VIRTUALENV=1
        export PIP_USE_PEP517=1
        export MANPAGER="sh -c 'col -bx | bat -l man -p'"
        export LANG="en_US.UTF-8"
        export LC_CTYPE="en_US.UTF-8"
        export LC_ALL="en_US.UTF-8"
        export LANGUAGE="en_US.UTF-8"

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
      shellAliases = {
        venv = "source .venv/bin/activate";
        helpme = "tldr --list | fzf | xargs tldr";
        gcs = "gcloud storage";
        cat = "bat -pP";
        ur = "uv run";
      };
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

  home.packages = with pkgs; [
    alejandra
    (azure-cli.withExtensions [
      azure-cli.extensions.azure-devops
    ])
    curl
    ffmpeg
    fzf
    font-awesome
    google-cloud-sdk
    graphviz
    imagemagick
    material-design-icons
    nerd-fonts.caskaydia-cove
    nerd-fonts.fantasque-sans-mono
    nil
    rsync
  ];

  home.file.".ipython/profile_default/ipython_config.py".text = ''
    c = get_config()

    c.InteractiveShell.ast_node_interactivity = "all"
    c.InteractiveShellApp.exec_lines = ["%autoreload 2"]
    c.InteractiveShellApp.extensions = ["autoreload"]
  '';

  home.stateVersion = "24.11";
  nixpkgs.config.allowUnfree = true;
  fonts.fontconfig.enable = true;
  programs.home-manager.enable = true;

  nix = {
    package = pkgs.nix;
    settings.experimental-features = ["nix-command" "flakes"];
  };

  # below is needed for Spotlight but Raycast is smart enough to read symlinks
  # home.activation = {
  #   aliasHomeManagerApplications = lib.hm.dag.entryAfter [ "writeBoundary" ] ""
  #     app_folder="${config.home.homeDirectory}/Applications/Home Manager Apps"
  #     rm -rf "$app_folder"
  #     mkdir -p "$app_folder"
  #     for app in $(find "$genProfilePath/home-path/Applications" -type l); do
  #         app_target="$app_folder/$(basename $app)"
  #         real_app="$(readlink $app)"
  #         echo "mkalias \"$real_app\" \"$app_target\"" >&2
  #         $DRY_RUN_CMD ${pkgs.mkalias}/bin/mkalias "$real_app" "$app_target"
  #     done
  #   "";
  # };
}
