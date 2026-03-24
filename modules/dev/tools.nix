# Development tools configuration
# Home-manager only module - includes common dev tools
{...}: {
  flake.modules.homeManager.dev-tools = {
    pkgs,
    lib,
    config,
    ...
  }: {
    home.packages = with pkgs; [
      alejandra # Nix formatter
    ];

    programs = {
      awscli.enable = true;
      bat.enable = true;
      broot.enable = true;
      btop.enable = true;
      jq.enable = true;
      pandoc.enable = true;
      zoxide.enable = true;

      ripgrep = {
        enable = true;
        arguments = [
          "--max-columns=150"
          "--max-columns-preview"
          "--hidden"
          "--glob=!.git/*"
          "--smart-case"
        ];
      };

      tealdeer = {
        enable = true;
        settings.updates.auto_update = true;
      };
    };
  };
}
