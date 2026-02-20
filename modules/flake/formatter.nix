# Formatter output - provides `nix fmt` command
{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    formatter = pkgs.alejandra;
  };
}
