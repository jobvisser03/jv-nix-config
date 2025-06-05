{pkgs, ...}: {

  stylix = {
    enable = true;
    autoEnable = false;
    targets = {
      gnome = { enable = false; }; # Disable GNOME if not needed
    };
    # Ensure colors are defined
    # TODO fix foliate error
    # base16Scheme = {
    #   base00 = "282828"; # ----
    #   base01 = "3c3836"; # ---
    #   base02 = "504945"; # --
    #   base03 = "665c54"; # -
    #   base04 = "bdae93"; # +
    #   base05 = "d5c4a1"; # ++
    #   base06 = "ebdbb2"; # +++
    #   base07 = "fbf1c7"; # ++++
    #   base08 = "fb4934"; # red
    #   base09 = "fe8019"; # orange
    #   base0A = "fabd2f"; # yellow
    #   base0B = "b8bb26"; # green
    #   base0C = "8ec07c"; # aqua/cyan
    #   base0D = "83a598"; # blue
    #   base0E = "d3869b"; # purple
    #   base0F = "d65d0e"; # brown
    # };
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
    # image = ../../non-nix-configs/non-nix-configs/nixos-wallpaper-catppuccin-frappe.png;
    # polarity = "dark";
    # cursor = {
    #   package = pkgs.capitaine-cursors-themed;
    #   name = "Capitaine Cursors (Gruvbox)";
    #   size = 32;
    # };
  };
}
