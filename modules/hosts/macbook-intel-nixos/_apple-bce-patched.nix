# Patched apple-bce kernel module with suspend/resume support
# Source: https://github.com/klizas/apple-bce-drv (branch: aur)
# This fork by klizas adds internal suspend/resume handling to the driver,
# eliminating the need for module unloading/reloading on suspend/resume.
{
  stdenv,
  lib,
  fetchFromGitHub,
  kernel,
}:
stdenv.mkDerivation rec {
  pname = "apple-bce-patched";
  version = "unstable-2024-02-08";

  src = fetchFromGitHub {
    owner = "klizas";
    repo = "apple-bce-drv";
    rev = "b607bd815af83d5c46ff08395c9b25c93b7fab00";
    hash = "sha256-hMS7ZU04daJcgz4OpRBhLuUjqnoIr3q0vakNYAivQXk=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];

  buildPhase = ''
    runHook preBuild
    make $makeFlags
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D apple-bce.ko $out/lib/modules/${kernel.modDirVersion}/extra/apple-bce.ko
    runHook postInstall
  '';

  meta = with lib; {
    description = "Apple BCE (Buffer Copy Engine) driver for T2 Macs with suspend/resume support";
    homepage = "https://github.com/klizas/apple-bce-drv";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
