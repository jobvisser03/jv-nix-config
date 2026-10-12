# Network unlock (Clevis + Tang + TPM2)

LUKS roots on `homeserver` and `framework-13-pro` unlock without a passphrase
only when **both** of these answer during boot:

- the machine's own TPM2, sealed to PCR 7 (Secure Boot policy), and
- a Tang server on the home LAN (`192.168.178.0/24`).

If either one fails, the normal LUKS passphrase prompt still works. The prompt
appears on the console, through JetKVM, or over initrd SSH on the homeserver.

Module: `modules/nixos/network-unlock/default.nix` (`nixos/network-unlock`,
`nixos/tang-server`). Pattern adapted from the `htpc` host in
[Riezebos/nix](https://github.com/Riezebos/nix) (private).

## Threat model

| Situation | Result |
| --- | --- |
| Normal boot at home | Unlocks unattended |
| Whole machine stolen (no Tang) | Passphrase required |
| Disk(s) removed (no TPM) | Passphrase required |
| Booted from other media at home | TPM refuses (PCR 7 changes) → passphrase |
| Laptop away from home | Passphrase required |
| Firmware / Secure Boot key change | PCR 7 changes → passphrase, then `bind --replace` |

The Clevis policy is `sss` with threshold 2: TPM2 plus one Tang. With several
Tang servers the Tang part is a nested `sss` with threshold 1, so any one of
them is enough. Two Tang servers without the TPM never are.

A systemd-cryptenroll TPM2-only token defeats this, because it unlocks
anywhere. Remove it with `network-unlock drop-systemd-tpm2` after `bind`.

## Tang servers

| Host | URL | Serves |
| --- | --- | --- |
| larkbox | `http://192.168.178.190:7654` | homeserver, framework |
| homeserver | not yet in any policy | framework, once its IP is reserved |

- Both IPs need a DHCP reservation in the FritzBox. The initrd has no
  mDNS or DNS.
- Tang answers only to the LAN subnet and loopback (`services.tang.ipAddressAllow`).
  Port 7654 is not forwarded on the router.
- Keys are created on the first request in `/var/lib/private/tang`. If they are
  lost or rotated, every binding stops working. Clients then fall back to the
  passphrase until you run `bind --replace`. Backing the keys up is optional:
  losing them is an inconvenience, not data loss.
- Show the signing key thumbprints with `ssh larkbox tang-show-keys 7654`.

## The `network-unlock` helper

Each host gets a `network-unlock` command with its device, Tang URLs, PCRs and
Wi-Fi interface baked in:

```sh
sudo network-unlock status             # bindings, tokens, Tang reachability
sudo network-unlock wifi               # (Wi-Fi hosts) write the initrd Wi-Fi PSK
sudo network-unlock bind               # add Tang + TPM2 binding, verify it
sudo network-unlock bind --replace     # new binding, verify, remove old one
sudo network-unlock drop-systemd-tpm2  # remove a TPM2-only systemd token
```

`bind` does the following:

1. Fetches each Tang advertisement and shows its key thumbprints. Compare them
   with `tang-show-keys` before answering `y`.
2. Saves a LUKS header backup to `/root/luks-header-*.bin`.
3. Asks for an existing passphrase.
4. Proves the new slot by decrypting through Tang and the TPM.

It never removes passphrase slots.

## framework-13-pro (migrating from TPM2-only)

The laptop has no ethernet, so the initrd joins the home Wi-Fi. The PSK, derived
from the active NetworkManager profile, is stored at
`/etc/secrets/initrd/wpa_supplicant.conf` and embedded in the initrd. That file
must exist before the first rebuild with this module, or the bootloader install
fails. Build the helper on its own first:

```sh
# 0. larkbox: deploy the tang-server module, then check it answers.
ssh larkbox tang-show-keys 7654

# 1. framework, at home on the home Wi-Fi:
nix build .#nixosConfigurations.framework-13-pro.config.system.build.networkUnlock -o /tmp/network-unlock
sudo /tmp/network-unlock/bin/network-unlock wifi
sudo nixos-rebuild switch --flake .#framework-13-pro

# 2. Bind and verify (prompts for the LUKS passphrase).
sudo network-unlock bind
sudo network-unlock status

# 3. Remove the old TPM2-only token so away-from-home boots ask for the passphrase.
sudo network-unlock drop-systemd-tpm2

# 4. Reboot at home: no prompt. Reboot with Wi-Fi out of range: passphrase prompt.
```

If the Wi-Fi password changes, rerun `network-unlock wifi` and rebuild.

If a kernel update changes the iwlwifi ucode name, initrd Wi-Fi stops working and
you only get the passphrase prompt. Fix it like this:

1. Check `journalctl -k -b | grep 'loaded firmware'`.
2. Update `initrdFirmware` in the host module.

## homeserver

The homeserver is wired (`r8169`) and also gets initrd SSH on port 2222 as a remote
passphrase fallback. Binding happens after Secure Boot is enforced, so PCR 7 is
already final. The steps are in [homeserver/install.md](homeserver/install.md#network-unlock).

## After firmware, BIOS or Secure Boot changes

PCR 7 changes when Secure Boot keys, `db`/`dbx` or the enforcement state change.
Some BIOS updates also change it. On the next boot:

1. Unlock with the passphrase (console, JetKVM, or `ssh -p 2222 root@homeserver`).
2. `sudo network-unlock bind --replace`
3. Reboot to confirm unattended unlock.

## Tradeoffs

- Initrd secrets (the Wi-Fi PSK and the homeserver initrd SSH host key) are
  appended to the initrd on the unencrypted ESP. Anyone with the disk can read
  them. Accepted: the PSK only grants LAN access, and the initrd host key only
  authenticates the unlock prompt.
- The Tang servers' keys sit on larkbox (unencrypted root). An attacker who
  steals larkbox **and** a client gets Tang. They still need that client's TPM
  to agree, which requires it to boot unmodified with Secure Boot on.
- The initrd grows by about 15 MB (clevis, tpm2-tools, curl, wpa_supplicant,
  firmware). Each generation on the 1 GiB ESP costs more.
