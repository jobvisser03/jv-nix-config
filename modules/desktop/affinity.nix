# Affinity creative suite (Photo & Designer) via Wine
# Home-manager module for NixOS x86_64 systems
{...}: {
  flake.modules.homeManager.affinity = {
    pkgs,
    inputs,
    config,
    lib,
    ...
  }: let
    affinityDataDir = "${config.xdg.dataHome}/affinity";
    # 192 DPI = 2x scaling for retina displays (default Wine DPI is 96)
    dpiHex = "000000c0";
  in {
    home.packages = [
      inputs.affinity-nix.packages.${pkgs.stdenv.hostPlatform.system}.photo
      inputs.affinity-nix.packages.${pkgs.stdenv.hostPlatform.system}.designer
    ];

    # Set Wine DPI to 192 (2x) for retina display scaling
    home.activation.affinityHiDpi = lib.hm.dag.entryAfter ["writeBoundary"] ''
      for user_reg in "${affinityDataDir}"/*/prefix/user.reg; do
        [ -f "$user_reg" ] || continue
        if grep -q '"LogPixels"' "$user_reg"; then
          ${pkgs.gnused}/bin/sed -i 's/"LogPixels"=dword:[0-9a-fA-F]*/"LogPixels"=dword:${dpiHex}/' "$user_reg"
        else
          ${pkgs.gnused}/bin/sed -i '/\[Control Panel\\\\Desktop\]/a "LogPixels"=dword:${dpiHex}' "$user_reg"
        fi
      done
    '';
  };
}
