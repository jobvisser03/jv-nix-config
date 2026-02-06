# Larkbox host-specific Home Manager configuration
{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    tree
  ];
}
