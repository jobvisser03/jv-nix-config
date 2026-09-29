# Larkbox Bluetooth audio

Larkbox acts as a Bluetooth speaker for phone audio. Spotify runs on the phone; no Spotify application or Spotify daemon runs on Larkbox.

```text
Phone Spotify → Bluetooth A2DP → Larkbox → PipeWire → DAC → hi-fi receiver
```

This avoids Hyprland dependency, Spotify Connect setup, and receiver source switching.

## Pair phone

Run on Larkbox:

```sh
bluetoothctl
power on
agent on
default-agent
discoverable on
pairable on
scan on
```

Select phone MAC address from scan output. In `bluetoothctl`, pair and trust phone:

```text
pair AA:BB:CC:DD:EE:FF
trust AA:BB:CC:DD:EE:FF
connect AA:BB:CC:DD:EE:FF
scan off
discoverable off
pairable off
quit
```

Replace `AA:BB:CC:DD:EE:FF` with phone Bluetooth MAC address. Enable `discoverable` and `pairable` only during initial pairing. Trust phone so later connections do not require pairing again.

On phone, select **Larkbox** as Bluetooth audio output and start Spotify. Any phone audio can use this path, not only Spotify.

## Check PipeWire routing

Inspect audio devices and streams:

```sh
wpctl status
pactl list short sinks
pactl list short sink-inputs
```

Set DAC as default output if required:

```sh
wpctl set-default <DAC-sink-id>
wpctl set-mute <DAC-sink-id> 0
wpctl set-volume <DAC-sink-id> 0.70
```

Use `pavucontrol` to move an active phone stream to DAC sink when automatic routing does not select it.

Larkbox configuration enables Bluetooth A2DP sink support in `modules/desktop/base.nix`. `a2dp_sink` means Larkbox receives stereo audio from phone. PipeWire then routes stream to current output sink, normally the DAC.

## Test after pairing

- Disconnect and reconnect phone.
- Reboot Larkbox.
- Put phone to sleep and wake it.
- Power-cycle receiver and DAC.
- Start video after Spotify stops.
- Confirm DAC remains default output.
- Confirm stream uses A2DP, not HFP/HSP.

If reconnect fails, run:

```sh
bluetoothctl connect AA:BB:CC:DD:EE:FF
```

If no phone stream appears, inspect recent user services:

```sh
systemctl --user status pipewire pipewire-pulse wireplumber
journalctl --user -u wireplumber -b
```

The phone must remain connected while playing. This is Bluetooth audio, not Spotify Connect. Calls and notification sounds may also use receiver output while phone is connected.
