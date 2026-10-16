# Syncthing ignore patterns for the Obsidian vault, shared by the desktop
# `syncthing` module and `homelab.services.obsidian-vault`. Keeps editor caches
# and Home Manager-managed Obsidian files (machine-specific Nix store links) out
# of sync, or HM activation clobbers synced copies. Darwin hosts copy this list
# by hand; see docs/syncthing-obsidian.md.
[
  "/.git"
  "/.obsidian/cache"
  "/.obsidian/workspace*.json"
  "/.obsidian/plugins"
  "/.obsidian/snippets"
  "/.obsidian/community-plugins.json*"
  "/.obsidian/appearance.json*"
  "/.obsidian/core-plugins*.json*"
  "/.obsidian/graph*.json"
  "*.hm-backup"
]
