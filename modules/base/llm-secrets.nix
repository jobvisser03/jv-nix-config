# LLM provider API keys — NixOS module
# sops-nix decrypts secrets to /run/secrets/* at boot (owner = user, mode 0400, tmpfs).
# Paths consumed by modules/dev/pi.nix via osConfig.sops.secrets.*.
#
# Edit secrets:
#   cd /path/to/jv-nix-config && sops secrets/shared.yaml
{...}: {
  flake.modules.nixos.llm-secrets = {username, ...}: {
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
  };
}
