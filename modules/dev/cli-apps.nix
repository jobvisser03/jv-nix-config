# Terminal-only applications for every interactive host, headless included.
# Home-manager only; GUI apps and fonts stay in desktop-apps.
{...}: {
  flake.modules.homeManager.cli-apps = {
    pkgs,
    lib,
    inputs,
    ...
  }: let
    packages = with pkgs; [
      # Core CLI tools
      curl
      ffmpeg
      fzf
      hurl
      yt-dlp
      fastfetch
      magic-wormhole

      # CLI maintenance
      # scan folders and files for cleanup using a rust implementation of du
      dust

      # Languages and formatters
      nil
      shfmt

      # Editors
      pkgs.unstable.vim
      pkgs.unstable.helix

      # Cloud and networking
      google-cloud-sdk
      azure-cli
      azure-storage-azcopy
      cachix
      tailscale
      speedtest-cli

      # DevOps & CI/CD
      glab
      docker-client

      # Graph visualization
      graphviz

      # Image manipulation
      imagemagick

      # TUI coding apps
      pkgs.unstable.opencode
      pkgs.unstable.claude-code
      inputs.herdr.packages.${pkgs.system}.default
      # pi-coding-agent is managed by modules/dev/pi.nix (pi.nix flake)

      # Reduce LLM token consumption
      pkgs.unstable.rtk
    ];
  in {
    home.packages =
      builtins.filter (pkg: lib.meta.availableOn pkgs.stdenv.hostPlatform pkg)
      packages;
  };
}
