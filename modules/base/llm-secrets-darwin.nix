# LLM provider API keys — home-manager module for nix-darwin
# sops-nix HM module decrypts secrets to ~/.config/sops-nix/secrets/*.
# Keys exported directly into zsh via $(cat ...) — no intermediate template file.
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
      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      defaultSopsFile = ../../secrets/shared.yaml;

      secrets = {
        openai_api_key = {};
        enexis_azure_openai_base_url = {};
        enexis_api_key = {};
        enexis_gitlab_api_key = {};
        openrouter_api_key = {};
      };
    };

    programs.zsh.initExtra = ''
      export OPENAI_API_KEY="$(cat ${config.sops.secrets.openai_api_key.path})"
      export ENEXIS_AZURE_OPENAI_BASE_URL="$(cat ${config.sops.secrets.enexis_azure_openai_base_url.path})"
      export ENEXIS_API_KEY="$(cat ${config.sops.secrets.enexis_api_key.path})"
      export ENEXIS_GITLAB_API_KEY="$(cat ${config.sops.secrets.enexis_gitlab_api_key.path})"
      export OPENROUTER_API_KEY="$(cat ${config.sops.secrets.openrouter_api_key.path})"
    '';
  };
}
