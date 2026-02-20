# VS Code Remote SSH support for NixOS
#
# VS Code Remote SSH downloads pre-compiled binaries that expect standard
# Linux paths (/lib64/ld-linux-x86-64.so.2). NixOS doesn't have these by
# default, so we use nix-ld to provide the dynamic linker shim.
#
# Usage: programs.vscodeRemoteSSH.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.programs.vscodeRemoteSSH = {
    enable = lib.mkEnableOption "VS Code Remote SSH support via nix-ld";
  };

  config = lib.mkIf config.programs.vscodeRemoteSSH.enable {
    programs.nix-ld = {
      enable = true;

      # Libraries needed by VS Code Server and common extensions
      libraries = with pkgs; [
        # Core - required by VS Code Server
        stdenv.cc.cc.lib # libstdc++

        # Compression
        zlib

        # SSL/TLS - Python, network extensions
        openssl

        # Unicode - various extensions
        icu

        # Network
        curl
        nss
        nspr

        # GLib utilities
        glib

        # Python extensions may need these
        libffi
        readline
        ncurses
        xz
        bzip2
        sqlite
      ];
    };
  };
}
