# Base SOPS secret management configuration
{inputs, ...}: {
  flake.modules.nixos.sops = {pkgs, ...}: {
    imports = [inputs.sops-nix.nixosModules.sops];

    environment.systemPackages = with pkgs; [age sops ssh-to-age];

    sops = {
      age = {
        # sops-nix converts this SSH host key to the matching ssh-to-age identity.
        # Keep .sops.yaml recipients in ssh-to-age age format, not native SSH format.
        sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

        # Host key supplies the system identity; no separate age key file needed.
        keyFile = null;
      };
    };
  };
}
