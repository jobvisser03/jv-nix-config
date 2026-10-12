# Body of the `network-unlock` helper. The Nix wrapper prepends:
#   DEVICE TANG_URLS TPM2_PCRS WIFI_INTERFACE WIFI_CONF
# Adapted from Riezebos/nix hosts/htpc/{enroll,rebind}-network-unlock.sh.
umask 077
STATE_DIR=/etc/network-unlock

die() {
  echo "network-unlock: $*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: sudo network-unlock <command>

  status              Show Clevis bindings, LUKS tokens and Tang reachability
  wifi                Write the initrd Wi-Fi config from the active NM profile
  bind                Add a Tang + TPM2 (PCRs $TPM2_PCRS) binding
  bind --replace      Add a new binding, verify it, then remove the old one
  drop-systemd-tpm2   Remove the systemd-cryptenroll TPM2-only slot

Device: $DEVICE
Tang:   ${TANG_URLS[*]}
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] || die "run with sudo"
}

# Keyslots that hold a Clevis sss binding.
sss_slots() {
  clevis luks list -d "$DEVICE" | sed -n 's/^\([0-9][0-9]*\): sss .*/\1/p'
}

cmd_status() {
  echo "Device: $DEVICE"
  echo "TPM2 PCRs: $TPM2_PCRS"
  echo
  echo "Clevis bindings:"
  clevis luks list -d "$DEVICE" || true
  echo
  echo "LUKS2 tokens:"
  cryptsetup luksDump --dump-json-metadata "$DEVICE" |
    jq -r '.tokens | to_entries[] | "  \(.key): \(.value.type) (keyslots \(.value.keyslots | join(",")))"'
  echo
  for url in "${TANG_URLS[@]}"; do
    if curl -fsS -m 5 "$url/adv" >/dev/null; then
      echo "Tang $url: reachable"
    else
      echo "Tang $url: UNREACHABLE"
    fi
  done
}

# Derive a WPA PSK locally and write it for the initrd. The plaintext Wi-Fi
# password never leaves this process; only the derived PSK is stored.
cmd_wifi() {
  [[ -n $WIFI_INTERFACE ]] || die "this host has no networkUnlock.wifi.interface"
  local connection ssid key_mgmt psk derived_psk ssid_hex answer
  connection=$(nmcli --get-values GENERAL.CON-UUID device show "$WIFI_INTERFACE")
  [[ -n $connection ]] || die "$WIFI_INTERFACE is not connected"
  ssid=$(nmcli --escape no --get-values 802-11-wireless.ssid connection show "$connection")
  key_mgmt=$(nmcli --get-values 802-11-wireless-security.key-mgmt connection show "$connection")
  [[ $key_mgmt == wpa-psk ]] || die "expected a WPA-PSK profile, got '$key_mgmt'"
  read -r -p "Use Wi-Fi network '$ssid' for disk unlock? [y/N] " answer
  [[ $answer == [yY] ]] || die "aborted"

  psk=$(nmcli --show-secrets --escape no --get-values 802-11-wireless-security.psk connection show "$connection")
  if [[ $psk =~ ^[0-9a-fA-F]{64}$ ]]; then
    derived_psk=$psk
  else
    derived_psk=$(printf '%s\n' "$psk" | wpa_passphrase "$ssid" | sed -n 's/^[[:space:]]*psk=//p')
  fi
  unset psk
  [[ $derived_psk =~ ^[0-9a-fA-F]{64}$ ]] || die "could not derive the Wi-Fi PSK"
  ssid_hex=$(printf '%s' "$ssid" | od -An -tx1 | tr -d ' \n')

  install -d -m 0700 "$(dirname "$WIFI_CONF")"
  cat >"$WIFI_CONF.new" <<EOF
ctrl_interface=/run/wpa_supplicant
network={
    ssid=$ssid_hex
    psk=$derived_psk
    key_mgmt=WPA-PSK
}
EOF
  unset derived_psk
  chmod 0600 "$WIFI_CONF.new"
  mv "$WIFI_CONF.new" "$WIFI_CONF"
  echo "Wrote $WIFI_CONF. Rebuild to embed it in the initrd."
}

# Fetch a Tang advertisement and have the operator confirm its signing keys
# against `tang-show-keys` on the server. Nested sss cannot prompt, so the
# trusted advertisement is stored and referenced by path in the policy.
trust_adv() {
  local url=$1 out=$2 answer
  curl -fsS -m 10 "$url/adv" -o "$out.new" || die "cannot reach Tang at $url"
  echo "Tang $url signing key thumbprint(s):"
  jose fmt -j "$out.new" -g payload -y -o- |
    jose jwk use -i- -r -u verify -o- |
    jose jwk thp -i- -a S256 | sed "s/^/  /"
  echo
  echo "Compare with: ssh <tang-host> tang-show-keys ${url##*:}"
  read -r -p "Trust these keys? [y/N] " answer
  [[ $answer == [yY] ]] || die "advertisement for $url not trusted"
  mv "$out.new" "$out"
}

build_policy() {
  local tang='[]' i adv tpm2
  for i in "${!TANG_URLS[@]}"; do
    adv="$STATE_DIR/tang-$i.jws"
    tang=$(jq -c --arg url "${TANG_URLS[$i]}" --arg adv "$adv" '. + [{url: $url, adv: $adv}]' <<<"$tang")
  done
  tpm2=$(jq -cn --arg pcrs "$TPM2_PCRS" '{pcr_bank: "sha256", pcr_ids: $pcrs}')
  if [[ ${#TANG_URLS[@]} -eq 1 ]]; then
    jq -cn --argjson tang "$tang" --argjson tpm2 "$tpm2" \
      '{t: 2, pins: {tang: $tang, tpm2: [$tpm2]}}'
  else
    jq -cn --argjson tang "$tang" --argjson tpm2 "$tpm2" \
      '{t: 2, pins: {sss: [{t: 1, pins: {tang: $tang}}], tpm2: [$tpm2]}}'
  fi
}

cmd_bind() {
  local replace=false
  [[ ${1:-} == --replace ]] && replace=true
  [[ -c /dev/tpmrm0 ]] || die "no TPM2 device at /dev/tpmrm0"
  [[ $(cryptsetup luksDump --dump-json-metadata "$DEVICE" | jq '.keyslots | length') -gt 0 ]] ||
    die "$DEVICE has no keyslots"

  local -a old_slots
  mapfile -t old_slots < <(sss_slots)
  if [[ ${#old_slots[@]} -gt 0 && $replace == false ]]; then
    die "Clevis binding already in slot(s) ${old_slots[*]}; use 'bind --replace'"
  fi

  install -d -m 0700 "$STATE_DIR"
  local i
  for i in "${!TANG_URLS[@]}"; do
    trust_adv "${TANG_URLS[$i]}" "$STATE_DIR/tang-$i.jws"
  done
  local policy backup
  policy=$(build_policy)

  backup="/root/luks-header-$(date +%Y%m%dT%H%M%S).bin"
  cryptsetup luksHeaderBackup "$DEVICE" --header-backup-file "$backup"
  echo "Header backup: $backup"
  echo "Enter an existing LUKS passphrase when prompted."
  clevis luks bind -d "$DEVICE" sss "$policy"

  # The new slot is the sss slot that was not there before.
  local slot new_slot=""
  while read -r slot; do
    if [[ " ${old_slots[*]} " != *" $slot "* ]]; then
      new_slot=$slot
    fi
  done < <(sss_slots)
  [[ $new_slot =~ ^[0-9]+$ ]] || die "could not find the new Clevis slot"

  # Decrypt through Tang + TPM2 now, without touching the mounted root.
  clevis luks pass -d "$DEVICE" -s "$new_slot" |
    cryptsetup open --test-passphrase --key-slot "$new_slot" --key-file - "$DEVICE"
  echo "Slot $new_slot: Tang + TPM2 unlock verified."

  if [[ $replace == true ]]; then
    for slot in "${old_slots[@]}"; do
      clevis luks unbind -f -d "$DEVICE" -s "$slot"
      echo "Removed old Clevis slot $slot."
    done
  fi
  echo "Passphrase slots are unchanged. Reboot to test automatic unlock."
}

# A systemd-cryptenroll TPM2-only token unlocks without Tang and so defeats
# the "only at home" property. Remove it once Clevis is verified.
cmd_drop_systemd_tpm2() {
  [[ -n $(sss_slots) ]] || die "no Clevis binding yet; run 'bind' first"
  systemd-cryptenroll --wipe-slot=tpm2 "$DEVICE"
  echo "Removed systemd-tpm2 slot(s)."
}

case "${1:-}" in
status)
  require_root
  cmd_status
  ;;
wifi)
  require_root
  cmd_wifi
  ;;
bind)
  require_root
  cmd_bind "${2:-}"
  ;;
drop-systemd-tpm2)
  require_root
  cmd_drop_systemd_tpm2
  ;;
*)
  usage
  exit 1
  ;;
esac
