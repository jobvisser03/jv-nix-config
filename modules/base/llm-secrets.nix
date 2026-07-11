# LLM provider API keys
# Secrets stored in secrets/shared.yaml (encrypted with age).
# At boot, sops-nix decrypts them and renders /run/secrets/llm-env.sh
# (owner = active user, mode = 0400, lives only in RAM under /run).
# The shell sources that file — keys are never stored in plaintext on disk.
#
# Edit secrets:
#   cd /path/to/jv-nix-config && sops secrets/shared.yaml
#
# Add keys in shared.yaml:
#   openai_api_key: sk-...
#   anthropic_api_key: sk-ant-...
#   gemini_api_key: AIza...
#   openrouter_api_key: sk-or-...
{...}: {
  flake.modules.nixos.llm-secrets = {
    config,
    username,
    ...
  }: {
    sops.secrets = {
      openai_api_key = {
        sopsFile = ../../secrets/shared.yaml;
        owner = username;
        mode = "0400";
      };
      anthropic_api_key = {
        sopsFile = ../../secrets/shared.yaml;
        owner = username;
        mode = "0400";
      };
      gemini_api_key = {
        sopsFile = ../../secrets/shared.yaml;
        owner = username;
        mode = "0400";
      };
      openrouter_api_key = {
        sopsFile = ../../secrets/shared.yaml;
        owner = username;
        mode = "0400";
      };
    };

    # Template renders to /run/secrets/llm-env.sh with actual secret values.
    # sops-nix substitutes placeholders at activation time.
    sops.templates."llm-env.sh" = {
      owner = username;
      mode = "0400";
      path = "/run/secrets/llm-env.sh";
      content = ''
        export OPENAI_API_KEY="${config.sops.placeholder.openai_api_key}"
        export ANTHROPIC_API_KEY="${config.sops.placeholder.anthropic_api_key}"
        export GEMINI_API_KEY="${config.sops.placeholder.gemini_api_key}"
        export OPENROUTER_API_KEY="${config.sops.placeholder.openrouter_api_key}"
      '';
    };
  };
}
