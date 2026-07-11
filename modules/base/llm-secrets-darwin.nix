# LLM provider API keys - home-manager module for nix-darwin
# Works on macOS via sops-nix's home-manager module.
# Secrets decrypt to ~/.config/sops-nix/secrets/ using the user's age key.
#
# One-time setup per Mac (run ON the Mac):
#   mkdir -p ~/.config/sops/age
#   age-keygen -o ~/.config/sops/age/keys.txt
#   # Copy the printed public key into .sops.yaml, then:
#   # cd ~/repos/jv-nix-config && sops updatekeys secrets/shared.yaml
{inputs, ...}: {
  flake.modules.homeManager.llm-secrets-darwin = {
    config,
    lib,
    ...
  }: {
    imports = [inputs.sops-nix.homeManagerModules.sops];

    sops = {
      # User's personal age key — must exist at this path on each Mac
      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

      defaultSopsFile = ../../secrets/shared.yaml;

      secrets = {
        openai_api_key = {};
        anthropic_api_key = {};
        gemini_api_key = {};
        openrouter_api_key = {};
      };

      # Renders to ~/.config/sops-nix/secrets/llm-env.sh with real values.
      # Sourced by zsh on login.
      templates."llm-env.sh" = {
        path = "${config.xdg.configHome}/sops-nix/secrets/llm-env.sh";
        mode = "0400";
        content = ''
          export OPENAI_API_KEY="${config.sops.placeholder.openai_api_key}"
          export ANTHROPIC_API_KEY="${config.sops.placeholder.anthropic_api_key}"
          export GEMINI_API_KEY="${config.sops.placeholder.gemini_api_key}"
          export OPENROUTER_API_KEY="${config.sops.placeholder.openrouter_api_key}"
        '';
      };
    };
  };
}
