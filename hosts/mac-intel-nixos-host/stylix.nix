{pkgs, config, lib, inputs, ...}: {

  stylix = {
    enable = true;
    # autoEnable = false;
    targets = {
      gnome = { enable = false; }; # Disable GNOME if not needed
    };
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
    image = ../../non-nix-configs/nixos-wallpaper-catppuccin-frappe.png;
    polarity = "dark";
    cursor = {
      package = pkgs.capitaine-cursors-themed;
      name = "Capitaine Cursors (Gruvbox)";
      size = 32;
    };
  };
}
