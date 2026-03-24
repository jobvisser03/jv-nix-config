# Global metadata - programs, appearance, shared options
{
  lib,
  pkgs,
  ...
}: {
  flake.meta = {
    # Default programs used across configurations
    programs = {
      terminal = "wezterm";
      browser = "firefox";
      editor = "code";
      shell = "zsh";
    };

    # Appearance settings (used by stylix and other theming)
    appearance = {
      wallpaper = ../non-nix-configs/nix-wallpaper-binary-black.png;
      polarity = "dark";
      theme = "gruvbox-material-dark-medium";

      fonts = {
        sizes = {
          desktop = 14;
          applications = 14;
          popups = 14;
          terminal = 13;
        };
        sansSerif = {
          name = "Ubuntu Nerd Font";
          package = "nerd-fonts.ubuntu";
        };
        serif = {
          name = "Ubuntu Nerd Font";
          package = "nerd-fonts.ubuntu";
        };
        monospace = {
          name = "Iosevka Nerd Font";
          package = "nerd-fonts.iosevka";
        };
        emoji = {
          name = "Noto Color Emoji";
          package = "noto-fonts-color-emoji";
        };
      };

      cursor = {
        name = "Bibata-Modern-Classic";
        package = "bibata-cursors";
        size = 24;
      };

      icons = {
        package = "papirus-icon-theme";
        light = "Papirus-Light";
        dark = "Papirus-Dark";
      };

      opacity = {
        applications = 0.95;
        desktop = 0.95;
        popups = 0.75;
        terminal = 0.95;
      };
    };

    # Git settings used across configurations
    git = {
      name = "Job Visser";
      email = "job@dutchdataworks.com";
    };
  };
}
