{
  pkgs,
  lib,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    alejandra
    # Currently managing via brew to enable extension installations
    # azure-cli
    # ((pkgs.azure-cli.override {withImmutableConfig = false;}).withExtensions [
    #   pkgs.azure-cli-extensions.azure-devops
    #   # pkgs.azure-cli-extensions.ml  # Note: ml may still be broken in nixpkgs
    # ])
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
    nodejs_latest
    devenv
    neofetch
    vim
    hurl
    wezterm
    speedtest-cli
    docker-client # for the docker cli
    yt-dlp
    android-tools
    retroarch-free
  ];
  # TODO try and get firerfox nightly working https://nixos.wiki/wiki/Firefox
  # nixpkgs.overlays =
  #   let
  #     # Change this to a rev sha to pin
  #     moz-rev = "master";
  #     moz-url = builtins.fetchTarball { url = "https://github.com/mozilla/nixpkgs-mozilla/archive/${moz-rev}.tar.gz";};
  #     nightlyOverlay = (import "${moz-url}/firefox-overlay.nix");
  #   in [
  #     nightlyOverlay
  #   ];
  # programs.firefox.package = pkgs.latest.firefox-nightly-bin;
  programs = {
    firefox = {
      enable = true;
      profiles = {
        default = {
          id = 0;
          name = "home";
          isDefault = true;
          settings = {
            "browser.startup.homepage" = "https://duckduckgo.com";
            "browser.search.defaultenginename" = "ddg";
            "browser.search.order.1" = "ddg";
            "browser.urlbar.autoFill.adaptiveHistory.enabled" = true;

            "extensions.pocket.enabled" = false;
            "extensions.screenshots.disabled" = true;

            "browser.topsites.contile.enabled" = false;
            "browser.formfill.enable" = false;

            "browser.newtabpage.activity-stream.feeds.topsites" = false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
            "browser.newtabpage.activity-stream.feeds.snippets" = false;

            "browser.newtabpage.activity-stream.section.highlights.rows" = false;
            "browser.newtabpage.activity-stream.section.highlights.includePocket" =
              false;
            "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" =
              false;
            "browser.newtabpage.activity-stream.section.highlights.includeDownloads" =
              false;
            "browser.newtabpage.activity-stream.section.highlights.includeVisited" =
              false;

            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.system.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          };
          search = {
            force = true;
            default = "ddg";
            order = ["ddg" "google"];
            engines = {
              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["!np"];
              };
              "NixOS Wiki" = {
                urls = [{template = "https://nixos.wiki/index.php?search={searchTerms}";}];
                icon = "https://nixos.wiki/favicon.png";
                updateInterval = 24 * 60 * 60 * 1000; # every day
                definedAliases = ["!nw"];
              };
              "bing".metaData.hidden = true;
              "google".metaData.alias = "!g"; # builtin engines only support specifying one additional alias
            };
          };
          extensions.packages = with inputs.firefox-addons.packages.${pkgs.system}; [
            keepassxc-browser
            ublock-origin
            darkreader
            vimium
          ];
        };
      };
    };

    awscli.enable = true;
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
      # includes = [
      #   {
      #     path = "~/repos/volt/.gitconfig";
      #     condition = "gitdir:~/repos/volt/";
      #   }
      # ];
    };
    jq.enable = true;
    oh-my-posh = {
      enable = true;
      # useTheme = "powerlevel10k_rainbow";
      settings = {
        final_space = true;
        shell_integration = true;
        enable_cursor_positioning = true;
        iterm_features = [
          "remote_host"
          "current_dir"
          # "prompt_mark"
        ];
        # below part is mostly this file converted to nix with json2nix: https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/powerlevel10k_rainbow.omp.json
        # and then applying a strange workaround to make unicode characters work: https://github.com/NixOS/nix/issues/10082#issuecomment-2059228774
        blocks = [
          {
            alignment = "left";
            segments = [
              {
                background = "#d3d7cf";
                foreground = "#000000";
                # leading_diamond = builtins.fromJSON ''"\u256d\u2500\ue0b2"'';
                style = "diamond";
                template = " {{ if .WSL }}WSL at {{ end }}{{.Icon}} ";
                type = "os";
              }
              {
                background = "#3465a4";
                foreground = "#e4e4e4";
                powerline_symbol = builtins.fromJSON ''"\ue0b0"'';
                properties = {
                  home_icon = "~";
                  style = "full";
                };
                style = "powerline";
                template = builtins.fromJSON ''" \uf07c {{ .Path }} "'';
                type = "path";
              }
              {
                background = "#4e9a06";
                background_templates = [
                  "{{ if or (.Working.Changed) (.Staging.Changed) }}#c4a000{{ end }}"
                  "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#f26d50{{ end }}"
                  "{{ if gt .Ahead 0 }}#89d1dc{{ end }}"
                  "{{ if gt .Behind 0 }}#4e9a06{{ end }}"
                ];
                foreground = "#000000";
                powerline_symbol = builtins.fromJSON ''"\ue0b0"'';
                properties = {
                  branch_icon = builtins.fromJSON ''"\uf126 "'';
                  fetch_stash_count = true;
                  fetch_status = true;
                  fetch_upstream_icon = true;
                };
                style = "powerline";
                template = builtins.fromJSON ''" {{ .UpstreamIcon }}{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }} \uf046 {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }} \ueb4b {{ .StashCount }}{{ end }} "'';
                type = "git";
              }
            ];
            type = "prompt";
          }
          # Don't need the clock, ERROR etc. right aligned for now
          # {
          #   alignment = "right";
          #   segments = [
          #     {
          #       background = "#689f63";
          #       foreground = "#ffffff";
          #       invert_powerline = true;
          #       powerline_symbol = builtins.fromJSON ''"\ue0b2"'';
          #       properties = {
          #         fetch_version = true;
          #       };
          #       style = "powerline";
          #       template = builtins.fromJSON ''" {{ if .PackageManagerIcon }}{{ .PackageManagerIcon }} {{ end }}{{ .Full }} \ue718 "'';
          #       type = "node";
          #     }
          #     {
          #       background = "#00acd7";
          #       foreground = "#111111";
          #       invert_powerline = true;
          #       powerline_symbol = builtins.fromJSON ''"\ue0b2"'';
          #       properties = {
          #         fetch_version = true;
          #       };
          #       style = "powerline";
          #       template = builtins.fromJSON ''" {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} \ue627 "'';
          #       type = "go";
          #     }
          #     {
          #       background = "#4063D8";
          #       foreground = "#111111";
          #       invert_powerline = true;
          #       powerline_symbol = builtins.fromJSON ''"\ue0b2"'';
          #       properties = {
          #         fetch_version = true;
          #       };
          #       style = "powerline";
          #       template = builtins.fromJSON ''" {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} \ue624 "'';
          #       type = "julia";
          #     }
          #     {
          #       background = "#FFDE57";
          #       foreground = "#111111";
          #       invert_powerline = true;
          #       powerline_symbol = builtins.fromJSON ''"\ue0b2"'';
          #       properties = {
          #         display_mode = "files";
          #         fetch_virtual_env = false;
          #       };
          #       style = "powerline";
          #       template = builtins.fromJSON ''" {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} \ue235 "'';
          #       type = "python";
          #     }
          #     {
          #       background = "#AE1401";
          #       foreground = "#ffffff";
          #       invert_powerline = true;
          #       powerline_symbol = builtins.fromJSON ''"\ue0b2"'';
          #       properties = {
          #         display_mode = "files";
          #         fetch_version = true;
          #       };
          #       style = "powerline";
          #       template = builtins.fromJSON ''" {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} \ue791 "'';
          #       type = "ruby";
          #     }
          #     {
          #       background = "#FEAC19";
          #       foreground = "#ffffff";
          #       invert_powerline = true;
          #       powerline_symbol = builtins.fromJSON ''"\ue0b2"'';
          #       properties = {
          #         display_mode = "files";
          #         fetch_version = false;
          #       };
          #       style = "powerline";
          #       template = builtins.fromJSON ''" {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} \uf0e7"'';
          #       type = "azfunc";
          #     }
          #     {
          #       background_templates = [
          #         "{{if contains \"default\" .Profile}}#FFA400{{end}}"
          #         "{{if contains \"jan\" .Profile}}#f1184c{{end}}"
          #       ];
          #       foreground = "#ffffff";
          #       invert_powerline = true;
          #       powerline_symbol = builtins.fromJSON ''"\ue0b2"'';
          #       properties = {
          #         display_default = false;
          #       };
          #       style = "powerline";
          #       template = builtins.fromJSON ''" {{ .Profile }}{{ if .Region }}@{{ .Region }}{{ end }} \ue7ad "'';
          #       type = "aws";
          #     }
          #     {
          #       background = "#ffff66";
          #       foreground = "#111111";
          #       invert_powerline = true;
          #       powerline_symbol = builtins.fromJSON ''"\ue0b2"'';
          #       style = "powerline";
          #       template = builtins.fromJSON ''" \uf0ad "'';
          #       type = "root";
          #     }
          #     {
          #       background = "#c4a000";
          #       foreground = "#000000";
          #       invert_powerline = true;
          #       powerline_symbol = builtins.fromJSON ''"\ue0b2"'';
          #       style = "powerline";
          #       template = builtins.fromJSON ''" {{ .FormattedMs }} \uf252 "'';
          #       type = "executiontime";
          #     }
          #     {
          #       background = "#000000";
          #       background_templates = [
          #         "{{ if gt .Code 0 }}#cc2222{{ end }}"
          #       ];
          #       foreground = "#d3d7cf";
          #       invert_powerline = true;
          #       powerline_symbol = builtins.fromJSON ''"\ue0b2"'';
          #       properties = {
          #         always_enabled = true;
          #       };
          #       style = "powerline";
          #       template = builtins.fromJSON ''" {{ if gt .Code 0 }}{{ reason .Code }}{{ else }}\uf42e{{ end }} "'';
          #       type = "status";
          #     }
          #     {
          #       background = "#d3d7cf";
          #       foreground = "#000000";
          #       invert_powerline = true;
          #       style = "diamond";
          #       template = builtins.fromJSON ''" {{ .CurrentDate | date .Format }} \uf017 "'';
          #       # trailing_diamond = builtins.fromJSON ''"\ue0b0\u2500\u256e"'';
          #       type = "time";
          #     }
          #   ];
          #   type = "prompt";
          # }
          {
            alignment = "left";
            newline = true;
            segments = [
              {
                foreground = "#81ff91";
                foreground_templates = ["{{if gt .Code 0}}#ff3030{{end}}"];
                style = "diamond";
                template = builtins.fromJSON ''"\u276f"'';
                properties.always_enabled = true;
                type = "text";
              }
            ];
            type = "prompt";
          }
        ];
        console_title_template = "{{ .Shell }} in {{ .Folder }}";
        version = 3;
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
    tealdeer = {
      enable = true;
      settings.updates.auto_update = true;
    };
    zoxide.enable = true;
    kitty.enable = true; # for hyprland
    wezterm = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      extraConfig = builtins.readFile ../non-nix-configs/wezterm.lua;
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

        #function cursor {
        #    /Applications/Cursor.app/Contents/MacOS/Cursor "$@"
        #}

        bindkey "^ " autosuggest-accept
        test -e "$HOME/.iterm2_shell_integration.zsh" && source "$HOME/.iterm2_shell_integration.zsh"
      '';

      shellAliases = import ./alias.nix;

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

  home.file.".ipython/profile_default/ipython_config.py".text = ''
    c = get_config()

    c.InteractiveShell.ast_node_interactivity = "all"
    c.InteractiveShellApp.exec_lines = ["%autoreload 2"]
    c.InteractiveShellApp.extensions = ["autoreload"]
  '';

  home.stateVersion = "24.11";
  nixpkgs = {
    config.allowUnfree = true; # for things like spotify
  };

  fonts.fontconfig.enable = true;
  programs.home-manager.enable = true;

  nix = {
    # package = pkgs.nix;
    settings.experimental-features = ["nix-command" "flakes"];
  };
}
