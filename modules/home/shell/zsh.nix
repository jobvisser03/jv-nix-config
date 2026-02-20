# Zsh shell configuration
{lib, ...}: {
  flake.modules.home.zsh = {
    config,
    pkgs,
    ...
  }: {
    programs.zsh = {
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

      shellAliases = {
        # Nix rebuild aliases
        hm-mac = "home-manager switch --flake /Users/job/repos/jv-nix-config#mac-intel-hm";
        hm-nixos = "home-manager switch --flake /home/job/repos/jv-nix-config#mac-intel-nixos-hm";
        hm-work = "home-manager switch --flake /Users/job.visser/repos/jv-nix-config#mac-apple-silicon-hm";
        hm-larkbox = "ssh larkbox 'source /etc/bashrc && cd ~/repos/jv-nix-config && git pull && home-manager switch --flake ~/repos/jv-nix-config#linux-hm'";
        nd-work = "sudo darwin-rebuild switch --flake ~/repos/jv-nix-config#mac-apple-silicon-host";
        nd-mac = "sudo darwin-rebuild switch --flake ~/repos/jv-nix-config#mac-intel-host";
        nr = "sudo nixos-rebuild switch --flake ~/repos/jv-nix-config#mac-intel-nixos-host";
        nrl = "sudo nixos-rebuild switch --flake ~/repos/jv-nix-config#linux-larkbox-host";
        nup = "sudo nixos-rebuild switch --flake ~/repos/jv-nix-config#mac-intel-nixos-host --upgrade";
        hm-update = "nix flake update";

        # Utility aliases
        dup = "sudo systemctl list-units *docker*";
        venv = "source .venv/bin/activate";
        helpme = "tldr --list | fzf | xargs tldr";
        gcs = "gcloud storage";
        cat = "bat -pP";
        ur = "uv run";

        # Git aliases
        g = "git";
        gcl = "git clone";
        gl = "git pull";
        gplr = "git pull --rebase";
        gplum = "git pull upstream master";
        gp = "git push";
        gput = "git push --tags";
        gpuf = "git push --force";
        gpuu = "git push --set-upstream";
        gpuo = "git push origin";
        gpuom = "git push origin master";
        gpuar = "git remote | xargs -L1 git push";
        gpp = "git pull && git push";
        gf = "git fetch --all --prune";
        gft = "git fetch --all --prune --tags";
        gfv = "git fetch --all --prune --verbose";
        gftv = "git fetch --all --prune --tags --verbose";
        gfr = "git fetch && git rebase";
        ga = "git add";
        gap = "git add --patch";
        gall = "git add --all";
        gai = "git add --interactive";
        gau = "git add --update";
        grm = "git rm";
        gmv = "git mv";
        gs = "git status";
        gss = "git status --short";
        gd = "git diff";
        gdw = "git diff --word-diff";
        gds = "git diff --staged";
        gdws = "git diff --word-diff --staged";
        gdv = "git diff -w \"$@\" | vim -R -";
        gc = "git commit --verbose";
        gcam = "git commit --verbose --amend";
        gca = "git commit --verbose --all";
        gcm = "git commit --verbose -m";
        gci = "git commit --interactive";
        gac = "git add --all && git commit --verbose -m";
        gst = "git stash";
        gstpu = "git stash push";
        gstpo = "git stash pop";
        gstd = "git stash drop";
        gstl = "git stash list";
        grst = "git reset";
        gnuke = "git reset --hard && git clean -d --force -x";
        gclean = "git clean -d --force";
        gb = "git branch";
        gba = "git branch --all";
        gbt = "git branch --track";
        gbm = "git branch --move";
        gbdel = "git branch --delete --force";
        gco = "git checkout";
        gcob = "git checkout -b";
        gct = "git checkout --track";
        gcp = "git cherry-pick";
        gcpa = "git cherry-pick --abort";
        gcpc = "git cherry-pick --continue";
        gm = "git merge";
        gma = "git merge --abort";
        gmc = "git merge --continue";
        grb = "git rebase";
        grba = "git rebase --abort";
        grbc = "git rebase --continue";
        grbi = "git rebase --interactive";
        gt = "git tag";
        gta = "git tag --annotate";
        gtd = "git tag --delete";
        gtl = "git tag --list";
        glog = "git log --graph --pretty = format:\"%C(yellow)%h%Creset%C(green)%d%Creset %s %C(red)<%an> %C(cyan)(%cr)%Creset\" --abbrev-commit";
        gls = "gl --stat";
        gsl = "git shortlog --email";
        gsls = "git shortlog --email --summary --numbered";
        gr = "git remote";
        grv = "git remote -v";
        gra = "git remote add";
        gbs = "git bisect";
        gbsb = "git bisect bad";
        gbsg = "git bisect good";
        gbsr = "git bisect reset";
        gbss = "git bisect start";
        gignore = "git update-index --assume-unchanged";

        btsony = ''
          DEVICE_ID_XM6=$(blueutil --paired | grep "WH-1000XM6" | head -n 1 | awk -F '[,:] *' '{print $2}')
          if [ -n "$DEVICE_ID_XM6" ]; then
            echo "Found WH-1000XM6, connecting..."
            blueutil --connect "$DEVICE_ID_XM6"
          else
            echo "WH-1000XM6 not found, opening selection menu..."
            DEVICE_ID_FZF=$(blueutil --paired | fzf | awk -F '[,:] *' '{print $2}')
            if [ -n "$DEVICE_ID_FZF" ]; then
              blueutil --connect "$DEVICE_ID_FZF"
            else
              echo "No device selected from menu."
            fi
          fi
        '';
      };

      plugins = [
        {
          name = "fzf-tab";
          src = pkgs.fetchFromGitHub {
            owner = "Aloxaf";
            repo = "fzf-tab";
            rev = "c5c6e1d82910fb24072a10855c03e31ea2c51563";
            sha256 = "sha256-epFjEcSCRNkFZYzt72W0kHasjOv3IyDy/60FHgviVHI=";
          };
        }
      ];
    };
  };
}
