# Stylix theming configuration
# NixOS and home-manager module
{...}: {
  flake.modules = {
    # NixOS stylix configuration
    nixos.stylix = {
      pkgs,
      lib,
      config,
      ...
    }: {
      stylix = {
        enable = true;
        image = ../../non-nix-configs/nix-wallpaper-binary-black.png;
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
        };

        icons = {
          enable = true;
          package = pkgs.papirus-icon-theme;
          light = "Papirus-Light";
          dark = "Papirus-Dark";
        };
      };
    };

    # Home-manager stylix configuration (inherits from NixOS when using useGlobalPkgs)
    homeManager.stylix = {
      pkgs,
      lib,
      config,
      ...
    }: {
      # Stylix home-manager module is automatically applied when enabled at NixOS level
      # This module can be used for home-manager-specific stylix overrides

      stylix.targets.firefox.profileNames = ["default"];
      stylix.targets.vscode.enable = false;
    };
  };
}
