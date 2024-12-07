{pkgs, ...}: {
  home.packages = with pkgs; [
    alt-tab-macos
    iina
  ];

  home.homeDirectory = "/Users/simon";
}
