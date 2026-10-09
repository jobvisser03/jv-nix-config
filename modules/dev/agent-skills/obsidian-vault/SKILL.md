---
name: obsidian-vault
description: Maintain the user's Obsidian vault at ~/syncthing/obsidian_vault (PARA folders, links-vs-tags rules, Tasks plugin, Syncthing + git). Use when the user asks to organise, clean up, file, archive, retag, relink or bulk-edit their notes; to file notes into PARA; to add Obsidian plugins; or to fix broken links, tags or sync conflicts.
---

# Obsidian vault maintenance

**The conventions live in the vault itself, in `30 Resources/Vault Manual.md`.** Read it before you move, file or retag anything; it is the source of truth for folder rules, tag lists and Tasks syntax. If the manual and this skill disagree, follow the manual, and update this skill.

## Facts

| | |
|---|---|
| Vault | `~/syncthing/obsidian_vault` |
| Sync | Syncthing folder id `6wlbb-itm77`. Other devices connect to it. |
| History | Local git repo in the vault (`.git` is in `.stignore`). |
| Plugins | Managed by nix: `~/repos/jv-nix-config/modules/desktop/obsidian.nix` (`defaultSettings.corePlugins` / `communityPlugins`). The plugin set comes from the `obsidian-extensions` flake input. `.obsidian/{community-plugins,core-plugins,appearance}.json` are symlinks into the nix store, so never edit them by hand. |
| Python | There is **no system python**. Use: `nix shell nixpkgs#python3 -c python3 …` |

User context: **Dutch Dataworks** is their freelance company (client: Enexis). **Data Mastery** is their training company (customer: Veneficus). Both are Areas under `20 Areas/Business/`, never Projects. "GenCV" means the Enexis computer-vision team (`#enexis/cv-team`), not `[[CV-Generator]]`.

## Core rules (summary of the manual)

1. **The folder shows how active a note is**:
   - `00 Inbox` → `10 Projects/<Enexis|Personal|client>` → `20 Areas/<area>` → `30 Resources/<kind>` → `40 Archive/<client>`
   - `Journals/`, `Templates/` and `Attachments/` are outside PARA.
2. **A thing is a `[[link]]`, a kind or a status is a `#tag`.** This covers people, projects, clients, organisations, areas, and topics that have their own note. Only links show up in *Linked mentions*. Lists and note types are tags (`#to/watch`, `#feedback`), and each gets a query note in `30 Resources/Lists/`.
3. **Tags are lowercase and hyphenated, and can be nested** (`#enexis/genai-team`). Never use a tag for something that has its own note.
4. **Tasks use Tasks plugin format.**
   - Priority `⏫ 🔼 🔽`; dates `📅` due, `⏳` scheduled, `🛫` start, followed by `YYYY-MM-DD`.
   - These markers go **at the end of the line**, after links and text. Only tags may follow them.
   - There is no `#inbox`; use `#someday` for "not now".
5. **Properties instead of PARA tags.** Use `type: person|organisation|project|cheatsheet`, plus `status: active|done` and `client: "[[X]]"` on projects. No `tags: [Project/Area/…]`.
6. **Links use shortest paths** (`[[Note]]`, never `[[Folder/Note]]`). Every note name must be **unique** across the vault.
7. **Attachments** live in `Attachments/`, embedded as `![[file]]`.

## Safety protocol for bulk changes

Small edits to one or two notes only need a commit before and after. For anything that touches many files, moves files, or runs a script over the vault:

1. **Obsidian must be closed** on this machine. Check both:
   - `grep -o '"path":"[^"]*","ts":[0-9]*,"open":true' ~/.config/obsidian/obsidian.json`, which shows which vaults are marked open.
   - The command lines of running Electron processes:
     ```
     for p in $(pgrep electron); do tr '\0' ' ' </proc/$p/cmdline | grep -o -m1 -i 'obsidian\|app-path=[^ ]*'; done
     ```
     Signal also runs on Electron, so a running Electron process is not necessarily Obsidian.

   If Obsidian has the vault open, **stop and ask the user to quit it**. Never kill it yourself.
2. **Pause Syncthing**: `syncthing cli config folders 6wlbb-itm77 paused set true`. Confirm with `… paused get`.
3. **Commit first**: `git -C ~/syncthing/obsidian_vault add -A && git -C ~/syncthing/obsidian_vault commit -m "before <change>"`. Don't commit if the user said not to; ask instead.
4. **Make the change**, then review `git diff --word-diff=plain` and grep it for each rule you applied. Check that no links broke and no duplicate note names appeared. If the change is large or structural, show the user a summary before committing.
5. **Commit, then resume Syncthing**: `… paused set false`. Check sync health:
   ```
   K=$(syncthing cli config gui apikey get)
   curl -s -H "X-API-Key: $K" "http://127.0.0.1:8384/rest/db/status?folder=6wlbb-itm77"
   ```
   It should show `state: idle`, `needFiles: 0`, `errors: 0`. Look for new `*conflict*` files.

**Never move or rename notes with `mv` without also rewriting the links to them.** For one or a few notes, tell the user to do it inside Obsidian (*Automatically update internal links* is on). Otherwise rewrite links in the same scripted change and verify them.

## Common tasks

- **Empty the inbox:** for each note in `00 Inbox/`, propose a destination (project, area, resource, or archive) based on its content and links. Move it after the user agrees.
- **Archive a finished project:** move it from `10 Projects/<X>/…` to `40 Archive/<client>/…` and set `status: done`. For a single note, dragging it in Obsidian is simplest.
- **New client:**
  1. Create a note in `20 Areas/Business/Dutch Dataworks/<Client>.md` and a folder `10 Projects/<Client>/`.
  2. If the client was tagged before (`#client`, `#client/<team>`), replace those with `[[Client]]` (keeping `#client/<team>` as a tag where the team matters).
- **Lead or prospect:** create `30 Resources/Organisations/<Name>.md` with `type: organisation` and `business: "[[Dutch Dataworks]]"`.
- **A tag should become a link** (it turned into a "thing"): create or choose the target note, then replace the tag with `[[Note]]` across the vault, following the safety protocol.
- **A new list:** use the `#to/<x>` tag, then create `30 Resources/Lists/To <x>.md` with the block below:
  ````
  ```query
  tag:#to/<x>
  ```
  ````
- **Health check** (when asked to tidy up): look for tag case variants, tags that match a note name, duplicate note names, notes outside PARA, attachments outside `Attachments/`, conflict files and empty stubs. Summarise and propose fixes; don't dump raw output.
- **Add an Obsidian plugin:**
  1. Check that it exists: `nix eval --impure --json --expr 'let f = builtins.getFlake (toString ~/repos/jv-nix-config); in builtins.attrNames f.inputs.obsidian-extensions.legacyPackages.x86_64-linux.obsidianPlugins' | tr ',' '\n' | grep -i <name>`
  2. Add `plugins.<name>` to `communityPlugins` in `modules/desktop/obsidian.nix`.
  3. Run `nh os build ~/repos/jv-nix-config` to verify, then commit in the nix repo.
  4. The user has to run `nh os switch ~/repos/jv-nix-config` themselves, because it needs sudo.
- **Conflict files:** diff each file against its counterpart (strip `__` and `conflicted`), merge only the lines that are new, then delete the conflict file.
- **Empty stubs:** don't delete them: they hold backlinks. Ask the user whether to fill them in or remove them.

## Gotchas

- **Single-letter tags** (`#A`) need the tag regex `#([A-Za-z](?:[\w/-]*\w)?)`. A pattern that requires two or more characters silently skips them.
- **Protect inline code, code fences, URLs and frontmatter** from scripted link and tag rewrites, or examples in notes such as the Vault Manual get changed.
- **Names must be unique.** Two notes with the same name (e.g. `Enexis.md` and `cheatsheet/Enexis.md`) make `[[Enexis]]` ambiguous, so rename one (`Enexis cheatsheet.md`).
- **Unresolved links are normal in Obsidian.** They still collect backlinks. Only worry about links that a change *newly* broke.
- **`ls` is aliased to `eza --git`**, which is very slow in the vault. Use `command ls` or `find`.
- **Leave Obsidian alone:** never edit `.obsidian/*.json` that are symlinks into `/nix/store`, and never kill Obsidian.

## After any change

- Commit in the vault repo with a descriptive message.
- If a convention changed, **update `30 Resources/Vault Manual.md`** and this skill (in `~/repos/jv-nix-config/modules/dev/agent-skills/obsidian-vault/`, then rebuild), so both stay in sync.
- Report to the user what changed and whether Syncthing is running again.
