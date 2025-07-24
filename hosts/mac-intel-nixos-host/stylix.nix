{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
  stylix = {
    enable = true;
    # autoEnable = false;
    targets = {
      gnome = {enable = false;}; # Disable GNOME if not needed
    };
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
    image = ../../non-nix-configs/nix-wallpaper-binary-black.png;
    polarity = "dark";
    fonts = {
      sizes = {
        desktop = 12;
        applications = 12;
      };
    };
    cursor = {
      package = pkgs.capitaine-cursors-themed;
      name = "Capitaine Cursors (Gruvbox)";
      size = 28;
    };
  };
}
