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
    ...
  }: {
    # Pull in the pi.nix option declarations so programs.pi.coding-agent exists.
    imports = [inputs.pi.homeModules.default];

    programs.pi.coding-agent = {
      enable = true;

      # Plan-mode extension — stored in the nix config, path injected at
      # build time so it is always present regardless of home dir state.
      extensions = [./pi/plan-mode.ts];

      # Declarative settings merged into ~/.pi/agent/settings.json on each
      # activation.  pi auto-installs npm packages listed here on first run.
      settings = {
        packages = [
          # Web search, URL fetch, PDF extraction, GitHub clone
          "npm:pi-web-access"
        ];
      };
    };

    # Global AGENTS.md — loaded by pi at startup from ~/.pi/agent/AGENTS.md.
    # Tailored for Python / Nix devenv / uv workflow.
    home.file.".pi/agent/AGENTS.md".text = ''
      # Global Agent Instructions

      ## Environment
      - Python projects use `uv` for package management (not pip, not poetry)
      - Run `uv add <pkg>` / `uv remove <pkg>` to manage dependencies
      - Run `uv sync` after editing pyproject.toml
      - Nix dev environments are declared in `devenv.nix` (devenv / nix-community)
      - Prefer `devenv shell` or direnv (`.envrc`) over manual shell activation
      - Nix config is formatted with `alejandra` and linted via `nil`

      ## Workflow
      - Read existing code before suggesting changes
      - For nix projects, inspect `flake.nix` and `devenv.nix` first
      - Prefer `nix flake check` over ad-hoc `nix-build` calls
      - Run `nix fmt` after editing nix files

      ## Style
      - Be concise and minimal — avoid unnecessary abstractions
      - Comment only what is non-obvious
      - Prefer explicit over implicit
    '';
  };
}
