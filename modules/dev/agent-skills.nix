# Shared agent skills (SKILL.md format) for every coding agent.
#
# Each skill directory under ./agent-skills/ is linked into:
#   ~/.agents/skills/<name>  — Agent Skills standard: pi, codex, opencode
#   ~/.claude/skills/<name>  — Claude Code
# Pi reads ~/.agents/skills natively, so the skill is deliberately NOT also
# passed via programs.pi.coding-agent.skills (that would load it twice).
{...}: {
  flake.modules.homeManager.agent-skills = {lib, ...}: let
    skills = {
      obsidian-vault = ./agent-skills/obsidian-vault;
    };
  in {
    home.file = lib.mkMerge (lib.mapAttrsToList (name: path: {
        ".agents/skills/${name}".source = path;
        ".claude/skills/${name}".source = path;
      })
      skills);
  };
}
