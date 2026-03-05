# Root modules index for flake-parts
# This file is the entry point for the dendritic module structure
# Only includes flake-parts compatible modules
{...}: {
  imports = [
    # Flake infrastructure
    ./flake/systems.nix
    ./flake/flake-parts.nix
    ./flake/configurations.nix
    ./flake/treefmt.nix
    ./flake/shell.nix
    ./flake/overlays.nix

    # Global metadata
    ./meta.nix

    # Base modules
    ./base/nix.nix
    ./base/home.nix
    ./base/sops.nix

    # User definitions
    ./users/job.nix
    ./users/job-work.nix

    # Shell modules
    ./shell/zsh.nix
    ./shell/atuin.nix
    ./shell/oh-my-posh.nix
    ./shell/aliases.nix
    ./shell/direnv.nix
    ./shell/eza.nix
    ./shell/fd.nix

    # Dev tools
    ./dev/git.nix
    ./dev/tools.nix

    # Desktop modules (NixOS)
    ./desktop/stylix.nix
    ./desktop/hyprland.nix
    ./desktop/waybar.nix
    ./desktop/hyprlock.nix
    ./desktop/hypridle.nix
    ./desktop/rofi.nix
    ./desktop/terminals/wezterm.nix
    ./desktop/terminals/kitty.nix
    ./desktop/browsers/firefox.nix

    # Darwin-specific
    ./darwin/base.nix
    ./darwin/homebrew.nix

    # NixOS-specific
    ./nixos/base.nix
    ./system/power-management.nix
    ./system/vscode-server.nix

    # Homelab (wrapper for existing NixOS modules)
    ./homelab/flake-module.nix

    # Host definitions
    ./hosts/larkbox/default.nix
    ./hosts/macbook-intel-nixos/default.nix
    ./hosts/macbook-intel/default.nix
    ./hosts/macbook-silicon/default.nix
  ];
}
