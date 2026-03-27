# Kitty terminal configuration
# Home-manager only module
{...}: {
  flake.modules.homeManager.kitty = {
    pkgs,
    lib,
    config,
    ...
  }: {
    programs.kitty = {
      enable = true;
      settings = {
        cursor_trail = 3;
        cursor_trail_decay = "0.1 0.4";
        window_padding_width = 20;
      };

      keybindings = {
        "ctrl+shift+t" = "new_tab_with_cwd";
      };
    };
  };
}
