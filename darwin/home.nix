{pkgs, ...}: {
  home.homeDirectory = "/Users/simon";

  home.packages = with pkgs; [
    alt-tab-macos
    iina
  ];
}
