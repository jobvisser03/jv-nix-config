# sops-nix base configuration
# This module sets up the base sops configuration for secret management.
# Each host should import this and define its own secrets in a secrets.nix file.
{
  lib,
  config,
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
}
