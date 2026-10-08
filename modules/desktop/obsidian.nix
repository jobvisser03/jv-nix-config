{inputs, ...}: {
  flake.modules.homeManager.obsidian = {pkgs, ...}: let
    plugins = inputs.obsidian-extensions.legacyPackages.${pkgs.stdenv.hostPlatform.system}.obsidianPlugins;
  in {
    programs.obsidian = {
      enable = true;
      vaults.notes.target = "Documents/obsidian_kb";
      # Unlisted core plugins (sync, publish, ...) are written as disabled.
      defaultSettings.corePlugins = [
        "backlink"
        "bases"
        "bookmarks"
        "canvas"
        "command-palette"
        "daily-notes"
        "editor-status"
        "file-explorer"
        "file-recovery"
        "global-search"
        "graph"
        "note-composer"
        "outgoing-link"
        "outline"
        "page-preview"
        "properties"
        "switcher"
        "tag-pane"
        "templates"
        "word-count"
      ];
      defaultSettings.communityPlugins = [
        plugins.obsidian-outliner
        plugins.journals
        plugins.obsidian-importer
        plugins.obsidian-tasks-plugin
        plugins.obsidian-spaced-repetition
      ];
    };
  };
}
