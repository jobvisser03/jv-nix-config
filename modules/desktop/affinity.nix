# Affinity creative suite (Photo & Designer) via Wine
# Home-manager module for NixOS x86_64 systems
{...}: {
  flake.modules.homeManager.affinity = {
    pkgs,
    inputs,
    ...
  }: {
    home.packages = [
      inputs.affinity-nix.packages.${pkgs.stdenv.hostPlatform.system}.photo
      inputs.affinity-nix.packages.${pkgs.stdenv.hostPlatform.system}.designer
    ];
  };
}
