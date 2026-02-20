# sops-nix base configuration
{lib, ...}: {
  flake.modules.sops.base = {
    config,
    pkgs,
    ...
  }: {
    sops = {
      age = {
        # Use SSH host key for decryption (converted to age format automatically by sops-nix)
        sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

        # Don't use a separate age key file - SSH host key is sufficient
        keyFile = null;
      };
    };
  };
}
