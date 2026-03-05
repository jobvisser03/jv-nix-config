{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
  stylix = {
    enable = true;
    image = ../non-nix-configs/nix-wallpaper-binary-black.png;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";

    fonts = {
      sizes = {
        desktop = 14;
        applications = 14;
        popups = 14;
        terminal = 13;
      };
      sansSerif = {
        name = "Ubuntu Nerd Font";
        package = pkgs.nerd-fonts.ubuntu;
      };
      serif = {
        name = "Ubuntu Nerd Font";
        package = pkgs.nerd-fonts.ubuntu;
      };
      monospace = {
        name = "Iosevka Nerd Font";
        package = pkgs.nerd-fonts.iosevka;
      };
      emoji = {
        name = "Noto Color Emoji";
        package = pkgs.noto-fonts-color-emoji;
      };
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    opacity = {
      applications = 0.95;
      desktop = 0.95;
      popups = 0.75;
      terminal = 0.95;
    };

    targets = {
      gnome.enable = false;
      waybar = {
        addCss = false;
        font = "sansSerif";
      };
    };

    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      light = "Papirus-Light";
      dark = "Papirus-Dark";
    };
  };
}
