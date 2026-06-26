# Stylix theming configuration
# NixOS and home-manager module
{config, ...}: let
  appearance = config.flake.meta.appearance;
in {
  flake.modules = {
    # NixOS stylix configuration
    nixos.stylix = {
      pkgs,
      lib,
      ...
    }: let
      packageFrom = packagePath:
        lib.attrByPath (lib.splitString "." packagePath)
        (throw "Could not resolve appearance package '${packagePath}' in pkgs")
        pkgs;
    in {
      stylix = {
        enable = true;
        image = appearance.wallpaper;
        polarity = appearance.polarity;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/${appearance.theme}.yaml";

        fonts = {
          sizes = appearance.fonts.sizes;
          sansSerif = {
            inherit (appearance.fonts.sansSerif) name;
            package = packageFrom appearance.fonts.sansSerif.package;
          };
          serif = {
            inherit (appearance.fonts.serif) name;
            package = packageFrom appearance.fonts.serif.package;
          };
          monospace = {
            inherit (appearance.fonts.monospace) name;
            package = packageFrom appearance.fonts.monospace.package;
          };
          emoji = {
            inherit (appearance.fonts.emoji) name;
            package = packageFrom appearance.fonts.emoji.package;
          };
        };

        cursor = {
          inherit (appearance.cursor) name size;
          package = packageFrom appearance.cursor.package;
        };

        opacity = appearance.opacity;

        targets = {
          gnome.enable = false;
        };

        icons = {
          enable = true;
          package = packageFrom appearance.icons.package;
          inherit (appearance.icons) light dark;
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
