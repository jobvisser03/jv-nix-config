# Development shell for working on this flake
{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      name = "jv-nix-config";

      packages = with pkgs; [
        # Nix tools
        nil # Nix LSP
        alejandra # Nix formatter
        nix-tree # Visualize nix store
        nvd # Nix version diff

        # Secret management
        sops
        age

        # General utilities
        git
        jq
      ];

      shellHook = ''
        echo "Welcome to jv-nix-config development shell"
        echo ""
        echo "Available commands:"
        echo "  nix flake check    - Validate the flake"
        echo "  nix fmt            - Format all code"
        echo "  nix flake show     - Show available outputs"
        echo ""
      '';
    };
  };
}
