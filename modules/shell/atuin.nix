# Atuin shell history configuration
# Home-manager only module
{...}: {
  flake.modules.homeManager.atuin = {
    pkgs,
    lib,
    config,
    ...
  }: {
    programs.atuin = {
      enable = true;
      settings = {
        style = "compact";
        enter_accept = true;
        filter_mode_shell_up_key_binding = "directory";
        search_mode_shell_up_key_binding = "prefix";
        show_preview = false;
        show_tabs = false;
        ctrl_n_shortcuts = true;
        sync = {
          records = false;
        };
        auto_sync = false;
      };
    };
  };
}
