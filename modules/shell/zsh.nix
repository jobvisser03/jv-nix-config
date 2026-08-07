# ZSH shell configuration with plugins
# Home-manager only module
{
  lib,
  pkgs,
  ...
}: {
  flake.modules.homeManager.zsh = {
    pkgs,
    lib,
    config,
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
        # Hardcoded brew env (avoids slow eval of brew shellenv)
        export HOMEBREW_PREFIX="/opt/homebrew"
        export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
        export HOMEBREW_REPOSITORY="/opt/homebrew"
        export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
        export MANPATH="/opt/homebrew/share/man:$MANPATH"
        export INFOPATH="/opt/homebrew/share/info:$INFOPATH"

        export PATH="$HOME/.cargo/bin:$HOME/.omlx/bin:$HOME/.local/bin:$HOME/.rd/bin:$PATH"

        # SOPS age key: macOS defaults to ~/Library/Application Support, override for both platforms
        export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

        export PIP_REQUIRE_VIRTUALENV=1
        export PIP_USE_PEP517=1
        export MANPAGER="sh -c 'col -bx | bat -l man -p'"
        export LANG="en_US.UTF-8"
        export LC_CTYPE="en_US.UTF-8"
        export LC_ALL="en_US.UTF-8"
        export LANGUAGE="en_US.UTF-8"

        bindkey "^ " autosuggest-accept

        eval "$(devenv hook zsh)"
      '';

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
