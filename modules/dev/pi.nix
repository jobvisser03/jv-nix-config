# Pi coding agent — declarative home-manager configuration.
#
# Installs pi via the pi.nix flake (github:lukasl-dev/pi.nix), which provides
# a newer/wrapped package compared to the bare nixpkgs pi-coding-agent entry.
#
# Configured with:
#   - A global AGENTS.md tailored for the Python / Nix devenv / uv workflow
#   - Web search via the pi-web-access npm extension (auto-installed by pi)
#   - Plan mode via a local TypeScript extension (modules/dev/pi/plan-mode.ts)
{inputs, ...}: {
  flake.modules.homeManager.pi = {
    pkgs,
    lib,
    config,
    # osConfig = NixOS/darwin system config; present in both NixOS and nix-darwin HM.
    # NixOS: has sops.secrets (system sops-nix). Darwin: no sops at system level.
    osConfig ? {},
    ...
  }: let
    # NixOS: secrets live at /run/secrets/<name> via system sops-nix → use osConfig.
    # Darwin: secrets live in ~/.config/sops-nix/secrets/<name> via HM sops-nix → use config.
    secretPath = name:
      if pkgs.stdenv.isLinux
      then osConfig.sops.secrets.${name}.path
      else config.sops.secrets.${name}.path;
  in {
    # Pull in the pi.nix option declarations so programs.pi.coding-agent exists.
    imports = [inputs.pi.homeModules.default];

    programs.pi.coding-agent = {
      enable = true;

      # Plan-mode extension — stored in the nix config, path injected at
      # build time so it is always present regardless of home dir state.
      extensions = [./pi/plan-mode.ts];

      environment.OPENAI_API_KEY = secretPath "openai_api_key";
      environment.ENEXIS_API_KEY = secretPath "enexis_api_key";
      environment.ENEXIS_AZURE_OPENAI_BASE_URL = secretPath "enexis_azure_openai_base_url";
      environment.ENEXIS_GITLAB_API_KEY = secretPath "enexis_gitlab_api_key";
      environment.OPENROUTER_API_KEY = secretPath "openrouter_api_key";

      # Declarative settings merged into ~/.pi/agent/settings.json on each
      # activation.  pi auto-installs npm packages listed here on first run.
      settings = {
        packages = [
          # Web search, URL fetch, PDF extraction, GitHub clone
          "npm:pi-web-access"
          "npm:pi-caveman"
          "npm:@gaodes/pi-gitlab"
          "npm:pi-subagents"
          "npm:remote-pi"
        ];
      };
    };

    # Global AGENTS.md — loaded by pi at startup from ~/.pi/agent/AGENTS.md.
    # Tailored for Python / Nix devenv / uv workflow.
    home.file.".pi/agent/AGENTS.md".text = ''
        # Global Agent Instructions

        ## Environment
        - Python projects: `uv` for package management (not pip, not poetry)
        - Source layout: `src/<package_name>/`, build backend: `hatchling`
        - Nix dev environments declared in `devenv.nix` (devenv/nix-community)
        - Nix config formatted with `alejandra`, linted with `nil`

        ## uv commands
        - `uv add <pkg>` / `uv remove <pkg>` — add/remove deps (auto-updates `uv.lock`)
        - `uv add --dev <pkg>` — add to `[dependency-groups] dev`
        - `uv add --group <name> <pkg>` — add to named group
        - `uv lock` — regenerate `uv.lock` after manual `pyproject.toml` edits
        - `uv sync` — install from lock (no lock update); skip if `uv.sync.enable = true` in devenv.nix
      (devenv does it on shell entry)
        - `uv sync --frozen` — CI: install exact lock, no resolution
        - `uv run <cmd>` — run command in project venv
        - `uvx <tool>` — run tool ephemerally without installing

        ## Workspace / monorepo
        - Local packages declared in `[tool.uv.sources]` as `{ path = "packages/pkg", editable = true }`
        - Add with `uv add <pkg>` after declaring source; do not use `pip install -e`

        ## devenv workflow
        - Read `devenv.nix` before making changes
        - Enter shell: `devenv shell` (auto-runs `uv sync` if `uv.sync.enable = true`, installs git hooks)
        - Inside shell: run `uv run <cmd>` directly (venv activated)
        - Outside shell (one-shot): `devenv shell -- uv run <cmd>`
        - Run tests: `devenv test` (runs `enterTest` block, preferred) or `uv run pytest` inside shell
        - Pre-commit: use `prek` as drop-in replacement for pre-commit
        - Git hooks configured via `git-hooks.hooks` in devenv.nix; run manually with `prek run
      --all-files`

        ## Nix workflow
        - Prefer `nix flake check` over ad-hoc `nix-build`
        - Run `nix fmt` after editing `.nix` files

        ## Style
        - Be concise and minimal — avoid unnecessary abstractions
        - Comment only what is non-obvious
        - Prefer explicit over implicit
    '';
  };
}
