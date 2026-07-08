# oMLX macOS app — LLM inference server with native menubar UI
# Installs the .dmg from GitHub releases. After initial install, the built-in
# Sparkle auto-updater handles upgrades. Force reinstall by deleting
# /Applications/oMLX.app and running darwin-rebuild switch.
#
# The CLI server (`omlx` command) is managed separately via Homebrew.
{...}: {
  flake.modules.darwin.omlx = {
    pkgs,
    lib,
    config,
    ...
  }: let
    version = "0.4.4";

    omlx-app = pkgs.stdenv.mkDerivation {
      pname = "omlx-app";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/jundot/omlx/releases/download/v${version}/oMLX-${version}-macos26-27.dmg";
        sha256 = "1zaqalgk4ha028z588favxclhpp5i4fzhkvk1h58kxr6ah8npxbd";
      };

      # hdiutil requires macOS system services
      __noChroot = true;

      buildInputs = [pkgs.rsync];

      dontUnpack = true;
      dontConfigure = true;
      dontInstall = true;

      buildPhase = ''
        mnt=$(mktemp -d)
        /usr/bin/hdiutil attach -readonly -nobrowse -mountpoint "$mnt" "$src"
        mkdir -p "$out/Applications"
        cp -R "$mnt/oMLX.app" "$out/Applications/"
        /usr/bin/hdiutil detach "$mnt"
        rmdir "$mnt"
      '';

      meta = {
        description = "oMLX - LLM inference server with native macOS UI";
        homepage = "https://github.com/jundot/omlx";
        platforms = ["aarch64-darwin"];
      };
    };
  in {
    # Install only if not already present (let Sparkle auto-updater manage upgrades)
    system.activationScripts.applications.text = lib.mkAfter ''
      if [ ! -d "/Applications/oMLX.app" ]; then
        echo "Installing oMLX.app to /Applications..."
        ${pkgs.rsync}/bin/rsync -a --delete "${omlx-app}/Applications/oMLX.app/" "/Applications/oMLX.app/"
      fi
    '';
  };
}
