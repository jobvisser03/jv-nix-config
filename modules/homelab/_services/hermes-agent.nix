# Hermes Agent - centralized homelab gateway
{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.homelab.services.hermes-agent;
in {
  options.homelab.services.hermes-agent = {
    enable = lib.mkEnableOption "Hermes Agent gateway";
  };

  config = lib.mkIf cfg.enable {
    services.hermes-agent = {
      enable = true;
      package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.messaging;
      addToSystemPackages = true;
      environmentFiles = [config.sops.templates."hermes-agent.env".path];
      settings = {
        model.default = "anthropic/claude-sonnet-4";
        terminal.backend = "local";
      };
    };

    # Let host user use same state as gateway CLI.
    users.users.${username}.extraGroups = ["hermes"];
  };
}
