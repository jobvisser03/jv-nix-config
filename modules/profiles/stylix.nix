# Stylix theming profile - applies to both NixOS and home-manager
{lib, ...}: {
  flake.modules.profiles.stylix = {
    config,
    pkgs,
    ...
  }: {
    stylix = {
      enable = true;
      targets = {
        gnome.enable = false;
      };
      base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
      image = ../../non-nix-configs/nix-wallpaper-binary-black.png;
      polarity = "dark";
      fonts = {
        sizes = {
          desktop = 18;
          applications = 18;
        };
      };
      cursor = {
        package = pkgs.capitaine-cursors-themed;
        name = "Capitaine Cursors (Gruvbox)";
        size = 28;
      };
    };
  };
}
