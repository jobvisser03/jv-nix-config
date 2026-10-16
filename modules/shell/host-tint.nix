# Per-host terminal background tint
# Home-manager only module
#
# Every prompt emits OSC 11 (set background) or OSC 111 (reset to the
# terminal's own theme). Because the shell on the far side of an SSH session
# does the same, the background follows whichever host you're on and snaps
# back when the session ends. Works in kitty and wezterm (and most others).
{...}: {
  flake.modules.homeManager.host-tint = {
    lib,
    osConfig ? {},
    ...
  }: let
    # Hosts not listed keep the terminal's default background.
    tints = {
      homeserver = "#3b1518";
      larkbox = "#14301e";
      job-mac-nixos = "#2b1f3d";
    };
    hostName = toString (osConfig.networking.hostName or "");
    tint = tints.${hostName} or null;
    sequence =
      if tint == null
      then ''\e]111\e\\''
      else ''\e]11;${tint}\e\\'';
  in {
    programs.zsh.initContent = ''
      if [[ -o interactive && "$TERM" != dumb ]]; then
        _host_tint() { printf '${sequence}' }
        autoload -Uz add-zsh-hook
        add-zsh-hook precmd _host_tint
      fi
    '';
  };
}
