# Homeserver roadmap

Deferred work. Most items come from the `foundry` server in
[Riezebos/nix](https://github.com/Riezebos/nix) (private), which runs a mature
version of the same idea.

## Alerting through Healthchecks.io

Foundry's `modules/features/alerting.nix` is the pattern to copy. It needs only
one sops secret (the project ping key) and a template unit:

- A `healthchecks-fail@<slug>.service` template unit, attached through
  `OnFailure=` to the units that matter. Here those are `zfs-zed`, `smartd`,
  `sanoid`, `pcloud-*`, `immich-server`, `jellyfin` and `tangd`.
- `ExecStartPost=` success pings on timers (`pcloud-backup`,
  `pcloud-photos-pull`, `zfs-scrub`), so a job that silently stops running
  trips a dead-man alert.
- A ping helper that **always exits 0**. Foundry learned the hard way that a
  failing alert hook can fail its parent unit and roll back a deploy.
- `?create=1` on ping URLs auto-provisions checks, so no clicking in the UI.

ZED (`services.zfs.zed.settings`) can call the same helper on pool events.

## Versioned off-site backups

pCloud via `rclone sync --backup-dir` is a mirror with dated leftovers, not
history. Foundry uses restic to a Hetzner Storage Box with an **append-only**
key on the server and the full-access key only on the laptop. A compromised
server then cannot delete history. The same split works with `restic` +
`rclone serve restic --append-only` over SSH. Add a monthly `restic check`
and a yearly restore drill.

## deploy-rs with magic rollback

Deploys from the framework with `nixos-rebuild --target-host` have no rollback
if SSH or networking breaks. deploy-rs activates, waits for a confirmation over
SSH, and reverts on timeout. Foundry runs it from CI with `remoteBuild = true`.

## CI coverage

- Add `homeserver` to `.github/workflows/cachix.yml` once the disk IDs are
  filled in (the `REPLACE-ME` assertion fails evaluation until then).
- Foundry also evaluates the deploy config and the toplevel `drvPath` cheaply,
  without building, on every push.
- A weekly `DeterminateSystems/update-flake-lock` PR plus Dependabot for
  Actions keeps inputs moving under review.

## Unattended upgrades

`system.autoUpgrade` with `operation = "boot"` stages the new generation for
the next reboot and pulls `github:jobvisser03/jv-nix-config`. The server is a
puller; the laptop stays the authority on `flake.lock`. It only makes sense
once CI builds homeserver.

## Pre-commit secret scanning

Foundry runs `gitleaks protect --staged --redact` through git-hooks.nix, next to
alejandra. This repo has treefmt but no secret scanner. That is cheap insurance
in a repo that holds sops files and host keys' public halves.

## Smaller items

- `services.openssh.settings.AllowUsers` and `MaxAuthTries = 3` once the user
  list is settled.
- `ClientAliveInterval`/`ClientAliveCountMax` if remote deploys over flaky links
  start hanging (foundry hit this from CI runners).
- A second Tang server (homeserver, `192.168.178.43`) in the framework
  policy, so the laptop still unlocks at home when larkbox is down. The
  config line is ready; see [install.md](install.md#remaining-steps).
