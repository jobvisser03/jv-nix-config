{inputs, ...}: {
  flake.modules.homeManager.obsidian = {pkgs, ...}: let
    plugins = inputs.obsidian-extensions.legacyPackages.${pkgs.stdenv.hostPlatform.system}.obsidianPlugins;
  in {
    programs.obsidian = {
      enable = true;
      vaults.notes.target = "Documents/obsidian_kb";
      defaultSettings.communityPlugins = [
        plugins.obsidian-outliner
        plugins.journals
        plugins.obsidian-importer
      ];
    };
  };
}
