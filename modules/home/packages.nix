# Core packages for all home configurations
{lib, ...}: {
  flake.modules.home.packages = {
    config,
    pkgs,
    ...
  }: {
    home.packages = with pkgs; [
      alejandra
      curl
      ffmpeg
      fzf
      font-awesome
      google-cloud-sdk
      graphviz
      imagemagick
      material-design-icons
      nerd-fonts.caskaydia-cove
      nerd-fonts.fantasque-sans-mono
      nerd-fonts.sauce-code-pro
      nil
      rsync
      nodejs_22
      devenv
      neofetch
      vim
      hurl
      wezterm
      speedtest-cli
      docker-client
      yt-dlp
      android-tools
      opencode
      cachix
      tailscale
    ];
  };
}
