# AGENTS.md

Short orientation for coding agents. It points at the source of truth; it does
not replace the docs.

## Start here

- Repo structure, profiles, adding hosts/modules: [`README.md`](README.md)
- Framework laptop: [`docs/framework-13-pro.md`](docs/framework-13-pro.md)
- Homeserver: [`docs/homeserver/overview.md`](docs/homeserver/overview.md) (then install / operations / recovery / roadmap)
- LUKS network unlock (Clevis + Tang + TPM2): [`docs/network-unlock.md`](docs/network-unlock.md)

## Common commands

```sh
nix fmt
nix flake check
nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link
sudo nixos-rebuild switch --flake .#<host>
sops secrets/shared.yaml
```

## Working rules

- `flake.nix` stays minimal: `mkFlake` + `import-tree ./modules`. Every `.nix`
  file under `modules/` is a flake-parts module unless its path contains `/_`.
  Plain NixOS modules (hardware configs, disko layouts, host fragments) use a
  `_` prefix and are imported explicitly.
- Modules register under `flake.modules.{nixos,darwin,homeManager}.<name>`;
  hosts pick them in `modules/flake/configurations.nix`.
- New files must be `git add`-ed (or `git add -N`) before Nix evaluation sees them.
- Stable `nixpkgs` (26.05) for systems; `pkgs.unstable.<name>` only for tools that need it.
- Never commit private keys, decrypted secrets, LUKS passphrases or the ZFS
  `tank.key`. `.sops.yaml` holds only `ssh-to-age` public recipients.
- `homeserver` fails evaluation until its `REPLACE-ME` disk IDs are filled in. Check
  it with `extendModules` overriding `disko.devices.disk.*.device`, not by
  removing the assertion.
- disko commands are destructive. Never run `--mode disko` outside an install.
- Do not create or remove LUKS keyslots for the user. Run `network-unlock status`
  to inspect them.
