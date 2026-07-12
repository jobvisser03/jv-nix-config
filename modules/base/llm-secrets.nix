# LLM provider API keys — NixOS module
# sops-nix decrypts secrets to /run/secrets/* at boot (owner = user, mode 0400, tmpfs).
# Keys exported directly into zsh via $(cat ...) — no intermediate template file.
#
# Edit secrets:
#   cd /path/to/jv-nix-config && sops secrets/shared.yaml
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
      enexis_azure_openai_base_url = {
        sopsFile = ../../secrets/shared.yaml;
        owner = username;
        mode = "0400";
      };
      enexis_api_key = {
        sopsFile = ../../secrets/shared.yaml;
        owner = username;
        mode = "0400";
      };
      enexis_gitlab_api_key = {
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

    programs.zsh.interactiveShellInit = ''
      export OPENAI_API_KEY="$(cat ${config.sops.secrets.openai_api_key.path})"
      export ENEXIS_AZURE_OPENAI_BASE_URL="$(cat ${config.sops.secrets.enexis_azure_openai_base_url.path})"
      export ENEXIS_API_KEY="$(cat ${config.sops.secrets.enexis_api_key.path})"
      export ENEXIS_GITLAB_API_KEY="$(cat ${config.sops.secrets.enexis_gitlab_api_key.path})"
      export OPENROUTER_API_KEY="$(cat ${config.sops.secrets.openrouter_api_key.path})"
    '';
  };
}
