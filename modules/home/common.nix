# Base home-manager configuration - applies to all home configs
{lib, ...}: {
  flake.modules.home.common = {
    config,
    pkgs,
    ...
  }: {
    home.stateVersion = "24.11";

    nixpkgs.config.allowUnfree = true;
    fonts.fontconfig.enable = true;
    programs.home-manager.enable = true;

    nix.settings.experimental-features = ["nix-command" "flakes"];

    # IPython config
    home.file.".ipython/profile_default/ipython_config.py".text = ''
      c = get_config()
      c.InteractiveShell.ast_node_interactivity = "all"
      c.InteractiveShellApp.exec_lines = ["%autoreload 2"]
      c.InteractiveShellApp.extensions = ["autoreload"]
    '';
  };
}
