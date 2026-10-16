# Syncthing + Obsidian vault

The Obsidian vault syncs between hosts with Syncthing. Larkbox is the always-on peer and backs the vault up to pCloud; the laptops run Obsidian.

```text
framework-13-pro ─┐
                  ├─ Syncthing (folder "obsidian_vault", ID 6wlbb-itm77) ─ larkbox → pCloud
macbook-silicon ──┤
homeserver ───────┘  (Hermes agent)
```

Vault path on every host: `~/syncthing/obsidian_vault`. Homeserver is the exception: see [Homeserver (Hermes)](#homeserver-hermes).

## What is synced and what is not

Home Manager (`modules/desktop/obsidian.nix`) writes some `.obsidian/` files as symlinks into the Nix store. They are per-host, so Syncthing must ignore them; otherwise a synced copy replaces the symlink, the next switch moves it to `*.hm-backup`, and the hosts keep overwriting each other.

| Path in `.obsidian/` | Owner | Synced |
| --- | --- | --- |
| `community-plugins.json`, `plugins/` | Home Manager (`communityPlugins`) | no |
| `core-plugins.json` | Home Manager (`corePlugins`) | no |
| `appearance.json`, `snippets/` | Home Manager | no |
| `workspace*.json`, `graph.json`, `cache` | Obsidian, per-device view state | no |
| `*.hm-backup` | Home Manager backups | no |
| `app.json`, `hotkeys.json`, `bookmarks.json`, `daily-notes.json`, `types.json`, ... | Obsidian | yes |

To enable or disable a core or community plugin, edit `modules/desktop/obsidian.nix` and switch. Toggles in Obsidian's settings are reset on the next switch.

## Ignore list

The list lives in `modules/_obsidian-stignore.nix`. On NixOS the `syncthing` module (`modules/desktop/syncthing.nix`) and `homelab.services.obsidian-vault` write it to `.stignore` with a tmpfiles rule on every switch. On Darwin, add it by hand (see below).

```text
/.obsidian/cache
/.obsidian/workspace*.json
/.obsidian/plugins
/.obsidian/snippets
/.obsidian/community-plugins.json*
/.obsidian/appearance.json*
/.obsidian/core-plugins*.json*
/.obsidian/graph*.json
*.hm-backup
```

`.stignore` is not synced itself, so every host needs its own copy. When changing the list, update `modules/_obsidian-stignore.nix` and this file together.

## New NixOS host

1. Add `"syncthing"` and `"obsidian"` to the host's `modules` in `modules/flake/configurations.nix`.
2. Point the vault at the Syncthing folder in the host's `default.nix`:

   ```nix
   home-manager.users.${username}.programs.obsidian.vaults.notes.target =
     lib.mkForce "syncthing/obsidian_vault";
   ```

3. Switch: `nh os switch`. This creates `~/syncthing/obsidian_vault`, its `.stignore` and the Home Manager links.
4. Open the Syncthing UI at <http://127.0.0.1:8384> and copy the device ID (*Actions → Show ID*).
5. On Larkbox, add the new device and share `obsidian_vault` with it. Devices and folders are not declared in Nix (`overrideDevices = false`, `overrideFolders = false`), so this is done in the UI.
6. On the new host, accept the device and the folder. Set the folder path to `~/syncthing/obsidian_vault`. The existing `.stignore` is picked up.
7. Wait for the first sync, then open the vault in Obsidian.

The tmpfiles rule hardcodes `/home/job`; a host with another user needs that path changed.

## New Darwin host

nix-darwin installs Syncthing and runs it as a launchd user agent, but does not write `.stignore`.

1. Add `"syncthing"` and `"obsidian"` to the host's `modules` and set the vault target as above.
2. Switch: `nh darwin switch`. Home Manager creates `~/syncthing/obsidian_vault/.obsidian/` with its links.
3. Before accepting the folder, create the ignore file so the first sync does not overwrite the Home Manager links:

   ```sh
   cat > ~/syncthing/obsidian_vault/.stignore <<'EOF'
   /.obsidian/cache
   /.obsidian/workspace*.json
   /.obsidian/plugins
   /.obsidian/snippets
   /.obsidian/community-plugins.json*
   /.obsidian/appearance.json*
   /.obsidian/core-plugins*.json*
   /.obsidian/graph*.json
   *.hm-backup
   EOF
   ```

   For an existing folder, paste the same lines into *Folder → Edit → Ignore Patterns* in the Syncthing UI instead; it writes the same file.

4. Pair with Larkbox and accept `obsidian_vault` at `~/syncthing/obsidian_vault`, as for NixOS (steps 4–7).
5. Check the folder's *Ignore Patterns* tab shows the list.

Repeat step 3 on the Mac whenever the list in `modules/_obsidian-stignore.nix` changes.

## Homeserver (Hermes)

On homeserver the vault is there for the Hermes agent, not for Obsidian. `homelab.services.obsidian-vault` (`modules/homelab/_services/obsidian-vault.nix`) runs Syncthing and the git auto-commit. The host sets it to run as `hermes`, with the vault in Hermes' working directory, so the Hermes module itself knows nothing about the vault. Vault path:

```text
/var/lib/hermes/workspace/obsidian_vault
```

Hermes' bundled `obsidian` skill finds the vault through `OBSIDIAN_VAULT_PATH`. Homeserver sets it from `homelab.services.obsidian-vault.dir`.

The agent's terminal tool starts in `/var/lib/hermes/workspace`, and the service sandbox (`ProtectSystem=strict`) already allows writes there. The files belong to `hermes`, so you need no ACLs and no extra `ReadWritePaths`. A vault under `/home/job` would need both, because home directories are `0700`.

The folder is two-way: Hermes edits notes, and its edits sync to every device. Every 15 minutes the `obsidian-vault-autocommit` timer commits all vault changes to a local git repo in the vault. The repo is created on the first run, and `/.git` is in `.stignore`, so it never syncs.

The repo belongs to `hermes`. `/etc/gitconfig` marks the vault as a `safe.directory`, so `job` (through the `hermes` group) can run read-only commands such as `git status`, `git log` and `git diff`. Commands that write, such as `revert` and `commit`, must run as `hermes`. Run as `job`, they would fail or leave `job`-owned files in `.git` that break the timer. To undo a bad edit:

```sh
cd /var/lib/hermes/workspace/obsidian_vault
git log --stat
sudo -u hermes git revert <commit>
```

The revert is a normal change, so it syncs back out. The history lives only on homeserver; pCloud (from larkbox) is still the off-site copy.

Pairing:

1. Switch homeserver. Open the GUI through a tunnel: `ssh -L 8385:127.0.0.1:8384 homeserver`, then go to <http://127.0.0.1:8385>.
2. Copy homeserver's device ID. On larkbox, add the device with address `tcp://homeserver:22000`. Ports are closed on the LAN, so the peers connect over Tailscale MagicDNS. Share `obsidian_vault` with homeserver.
3. On homeserver, accept larkbox and the folder. Set the path to `/var/lib/hermes/workspace/obsidian_vault`. Do not keep the default `~/obsidian_vault`.
4. Optionally add larkbox's address on homeserver too (`tcp://larkbox:22000`).

## Cleanup after a conflict

Leftover files in `.obsidian/` are safe to delete on each host once they are ignored:

```sh
rm ~/syncthing/obsidian_vault/.obsidian/*.hm-backup
rm ~/syncthing/obsidian_vault/.obsidian/*.sync-conflict-*
```

A `*.sync-conflict-*` copy of a synced file (not in the ignore list) can hold real changes; compare it with the original before deleting.
