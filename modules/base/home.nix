# Base home-manager configuration - always included
{inputs, ...}: {
  flake.modules = {
    # Base home-manager module for all users
    homeManager.home = {
      pkgs,
      lib,
      ...
    }: {
      home.stateVersion = lib.mkDefault "24.11";

      # IPython configuration
      home.file.".ipython/profile_default/ipython_config.py".text = ''
        c = get_config()

        c.InteractiveShell.ast_node_interactivity = "all"
        c.InteractiveShellApp.exec_lines = ["%autoreload 2"]
        c.InteractiveShellApp.extensions = ["autoreload"]
      '';

      fonts.fontconfig.enable = true;
      programs.home-manager.enable = true;
    };

    # macOS-specific home config
    homeManager.home-darwin = {pkgs, ...}: {
      home.packages = with pkgs; [
        blueutil
      ];
      nix.package = pkgs.nix;
    };
  };
}
