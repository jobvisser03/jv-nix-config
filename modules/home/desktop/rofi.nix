# Rofi application launcher
{lib, ...}: {
  flake.modules.home.rofi = {
    config,
    pkgs,
    ...
  }: {
    programs.rofi = {
      enable = true;
      terminal = "${pkgs.kitty}/bin/kitty";
      extraConfig = {
        modi = "drun,run,window";
        show-icons = true;
        drun-display-format = "{name}";
        disable-history = false;
        hide-scrollbar = true;
        sidebar-mode = false;
      };
    };
  };
}
