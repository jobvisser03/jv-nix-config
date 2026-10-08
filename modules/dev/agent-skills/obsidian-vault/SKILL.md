---
name: obsidian-vault
description: Maintain the user's Obsidian vault at ~/syncthing/obsidian_vault (PARA folders, links-vs-tags rules, Tasks plugin, Syncthing + git). Use when the user asks to organise, clean up, audit, restructure, retag, relink, archive or bulk-edit their notes or vault; to file notes into PARA; to add Obsidian plugins; or to fix broken links, tags, conflicts or leftover Logseq syntax.
---

# Obsidian vault maintenance

The vault was migrated from Logseq to PARA on 2026-10-08. **The conventions live in the vault itself, in `30 Resources/Vault Manual.md`.** Read it before you move, file or retag anything; it is the source of truth for folder rules, tag lists and Tasks syntax. If the manual and this skill disagree, follow the manual, and update this skill.

## Facts

| | |
|---|---|
| Vault | `~/syncthing/obsidian_vault` |
| Sync | Syncthing folder id `6wlbb-itm77`. Other devices connect to it. |
| History | Local git repo in the vault (`.git` is in `.stignore`). Commits: `a4e2bcf` baseline after import, `9342975` PARA migration, `29123eb` manual, `54da7f8` post-migration settings |
| Backup from before the migration | `~/obsidian_vault_backup_2026-10-08` |
| Plugins | Managed by nix: `~/repos/jv-nix-config/modules/desktop/obsidian.nix` (`defaultSettings.corePlugins` / `communityPlugins`). The plugin set comes from the `obsidian-extensions` flake input. `.obsidian/{community-plugins,core-plugins,appearance}.json` are symlinks into the nix store, so never edit them by hand. |
| Original Logseq graph | `~/pcloud/dutch-dataworks/logseq_kb/` (`assets/` has some images) |
| Python | There is **no system python**. Use: `nix shell --impure --expr 'with import <nixpkgs> {}; python3.withPackages (p: [p.pyyaml])' -c python3 …` |
| Scripts | `scripts/` next to this SKILL.md. Managed in `~/repos/jv-nix-config/modules/dev/agent-skills/obsidian-vault/` and read-only once deployed, so edit them in the repo. |

User context: **Dutch Dataworks** is their freelance company (client: Enexis). **Data Mastery** is their training company (customer: Veneficus). Both are Areas under `20 Areas/Business/`, never Projects. "GenCV" means the Enexis computer-vision team (`#enexis/cv-team`), not `[[CV-Generator]]`.

## Core rules (summary of the manual)

1. **The folder shows how active a note is**:
   - `00 Inbox` → `10 Projects/<Enexis|Personal|client>` → `20 Areas/<area>` → `30 Resources/<kind>` → `40 Archive/<client>`
   - `Journals/`, `Templates/` and `Attachments/` are outside PARA.
2. **A thing is a `[[link]]`, a kind or a status is a `#tag`.** This covers people, projects, clients, organisations, areas, and topics that have their own note. Only links show up in *Linked mentions*. Lists and note types are tags (`#to/watch`, `#feedback`), and each gets a query note in `30 Resources/Lists/`.
3. **Tags are lowercase and hyphenated, and can be nested** (`#enexis/genai-team`). Never use a tag for something that has its own note.
4. **Tasks use Tasks plugin format.**
   - Priority `⏫ 🔼 🔽`; dates `📅` due, `⏳` scheduled, `🛫` start, followed by `YYYY-MM-DD`.
   - These markers go **at the end of the line**, after links and text.
   - There is no `#inbox`; use `#someday` for "not now".
5. **Properties instead of PARA tags.** Use `type: person|organisation|project|cheatsheet`, plus `status: active|done` and `client: "[[X]]"` on projects. No `tags: [Project/Area/…]`.
6. **Links use shortest paths** (`[[Note]]`, never `[[Folder/Note]]`). Every note name must be **unique** across the vault.

## Safety protocol: mandatory before any bulk or scripted change

Small edits to one or two notes need only steps 3 and 7. For anything that touches many files, moves files, or runs a script over the vault, do every step:

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
4. **Dry run**: run `--plan` and read `report.md`. It must show **0 newly unresolved links** and **no duplicate note names**.
5. **Run on a copy**:
   - `--apply --target ~/obsidian_vault_test`. The copy includes `.git`, so `git add -A && git diff --cached --word-diff=plain` there shows every change.
   - Grep the diff for each rule you changed, and look at real lines.
   - Ask the user to look at the copy in Obsidian for anything structural.
6. **Run it live**, then check:
   - `check_idempotent.py` shows `0 pending change(s)`.
   - `diff -rq -x .git -x .obsidian -x .trash <live> <test copy>` shows the live result is identical to the reviewed copy.
7. **Commit, delete the test copy, then resume Syncthing**: `… paused set false`. Check sync health:
   ```
   K=$(syncthing cli config gui apikey get)
   curl -s -H "X-API-Key: $K" "http://127.0.0.1:8384/rest/db/status?folder=6wlbb-itm77"
   ```
   It should show `state: idle`, `needFiles: 0`, `errors: 0`. Look for new `*conflict*` files.

Never move or rename notes with `mv` without also rewriting links. Use the script (it rewrites links), or tell the user to do it inside Obsidian (*Automatically update internal links* is on).

## Scripts

All of them take a vault path and default to the live vault. Run them with the nix python shown above.

### `scripts/audit.py [VAULT]` (read-only; start every maintenance session with it)
It reports:
- the tag inventory with case variants
- tags that match an existing note name (candidates to become links)
- duplicate note names
- unresolved links
- notes outside PARA
- attachments outside `Attachments/`
- conflict files
- empty stub notes
- leftover Logseq syntax (`[[Logseq/…]]`, `key:: value`, `{{query}}`, `../assets/`, `#inbox`, `#A/B/C`, `DEADLINE:`)

Summarise it for the user and propose fixes. Don't just dump the output.

### `scripts/vault_migrate.py --mapping M.yaml (--plan | --apply --target DIR) [--out DIR] [--force]`
A mapping-driven bulk rewriter. With `--plan` it writes `report.md` and `moves.csv` to `--out` (default: the current directory) and changes nothing. `--apply` refuses to run if links would break or note names would collide, unless you pass `--force`.

Every mapping section is optional, so a maintenance mapping can be tiny. The full reference is `scripts/mapping-2026-10-08-para-migration.yaml`.

```yaml
links:          # tag -> literal replacement (link and/or tag)
  newclient: "[[New Client]]"
  newclient/team-x: "[[New Client]] #newclient/team-x"
renames:        {old-tag: "#new-tag"}
drop:           [obsolete-tag]                 # remove tag, keep text
task_only:      {a: "⏫"}                       # only on checkbox lines
everywhere:     {inbox: ""}
links_replace:  {"old note name": "#tag"}      # replace a [[link]] with text
moves:          # vault-relative source -> destination | TRASH | MERGE:<dest>
  "10 Projects/Enexis/Meterstanden.md": "40 Archive/Enexis/Meterstanden.md"
file_overrides: # per-file tag exceptions
  Journals/2024-05-27.md: {project/gencv: "[[CV-Generator]]"}
stubs:          # create notes for new link targets
  - folder: 30 Resources/People
    properties: {type: person}
    names: [New Person]
properties:     # merge frontmatter into notes (keyed by destination path)
  "40 Archive/Enexis/Meterstanden.md": {status: done}
query_notes:    {Feedback: "#feedback"}        # create or append a ```query``` block
```

What the script handles automatically:
- **Moved and renamed notes:** links get rewritten, aliases are kept when the visible name changes, and the importer's path links (`[[X|Logseq/X]]`) are normalised.
- **`[[to/x]]` links** become `#to/x` tags, and a `To x` list note is created.
- **Task lines:** priority and date markers move to the end of the line. Logseq `— due [[date]]` and `DEADLINE: <…>` are converted.
- **Attachments:** files in the vault root go to `Attachments/`. `../assets/` links become `![[file]]`, and missing assets are copied from the Logseq graph (`--assets`).
- **Journals and conflict files:** journals named `YYYY_MM_DD` are renamed or merged. Conflict files go to `00 Inbox/_conflicts/`.
- **Left alone:** code blocks, inline code, URLs and frontmatter are never touched by tag or link rewrites.
- Files already inside a PARA folder stay where they are unless `moves` lists them, so reruns are safe.

### `scripts/check_idempotent.py VAULT MAPPING.yaml`
Re-applies a mapping in memory and lists everything that would still change. After a live run it must print `0 pending change(s)`.

## Common tasks

- **Archive a finished project:**
  1. Add a `moves:` entry from `10 Projects/<X>/…` to `40 Archive/<client>/…`, and set `status: done` via `properties:`.
  2. Run through the safety protocol.
  For a single note, telling the user to drag it in Obsidian is simpler.
- **New client:**
  1. Create a note in `20 Areas/Business/Dutch Dataworks/<Client>.md` and a folder `10 Projects/<Client>/`.
  2. If the client was tagged before, add `links: {client: "[[Client]]"}` and `client/<team>` → `"[[Client]] #client/<team>"`.
- **Lead or prospect:** create `30 Resources/Organisations/<Name>.md` with `type: organisation` and `business: "[[Dutch Dataworks]]"`.
- **A tag should become a link** (it turned into a "thing"):
  1. Add it to `links:`.
  2. Create or choose the target note, and add a `stubs:` entry if the note doesn't exist yet.
  3. Run the protocol.
- **A new list:** use the `#to/<x>` tag, then create `30 Resources/Lists/To <x>.md` with the block below:
  ````
  ```query
  tag:#to/<x>
  ```
  ````
- **Add an Obsidian plugin:**
  1. Check that it exists: `nix eval --impure --json --expr 'let f = builtins.getFlake (toString ~/repos/jv-nix-config); in builtins.attrNames f.inputs.obsidian-extensions.legacyPackages.x86_64-linux.obsidianPlugins' | tr ',' '\n' | grep -i <name>`
  2. Add `plugins.<name>` to `communityPlugins` in `modules/desktop/obsidian.nix`.
  3. Run `nh os build ~/repos/jv-nix-config` to verify, then commit in the nix repo.
  4. The user has to run `nh os switch ~/repos/jv-nix-config` themselves, because it needs sudo.
- **Conflict files:** diff each file against its counterpart (strip `__` and `conflicted`), merge only the lines that are new, then delete the conflict file.
- **Empty stubs:** list them from the audit. Don't delete them: they hold backlinks. Ask the user whether to fill them in or remove them.

## Gotchas learned the hard way

- **Single-letter tags** (`#A`) need the tag regex `#([A-Za-z](?:[\w/-]*\w)?)`. A pattern that requires two or more characters silently skips them.
- **Inline code and code fences must be protected** from link and tag rewrites, or examples in notes such as the Vault Manual get changed.
- **Tasks plugin markers** must come at the end of the task line. Text or `[[links]]` after `📅`/`⏫` stop the plugin from reading the task. Only tags may follow.
- **Names must be unique.** Two notes with the same name (e.g. `Enexis.md` and `cheatsheet/Enexis.md`) make `[[Enexis]]` ambiguous, so rename one (`Enexis cheatsheet.md`).
- **Duplicate journals:** `YYYY_MM_DD.md` and `YYYY-MM-DD.md` pairs held *different* content, so merge them; never drop one.
- **`ls` is aliased to `eza --git`**, which is very slow in the vault. Use `command ls` or `find`.
- **Long applies can time out in the foreground.** Run them in the background or with a longer timeout.
- **Unresolved links are normal in Obsidian.** They still collect backlinks. Measure *newly* unresolved links, not the total.
- **Images lost in Logseq:** 14 of them are missing from both the vault and the Logseq assets, so their embeds stay broken. Don't chase them.
- **Leave Obsidian alone:** never edit `.obsidian/*.json` that are symlinks into `/nix/store`, and never kill Obsidian.

## After any change

- Commit in the vault repo with a descriptive message.
- If a convention changed, **update `30 Resources/Vault Manual.md`** and this skill (in the nix repo, then rebuild), so both stay in sync.
- Report to the user what changed, the link-check result, and whether Syncthing is running again.
