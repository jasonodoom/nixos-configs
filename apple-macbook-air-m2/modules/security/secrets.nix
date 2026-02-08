# Agenix secrets management for theophany (macOS)
{ config, pkgs, lib, ... }:

{
  # Age encryption configuration
  # Secrets are decrypted at activation time and symlinked to /run/agenix/

  # GitHub token for creating issues on auto-upgrade failures
  age.secrets.gh-token = {
    file = ../../secrets/gh-token.age;
    mode = "0400";
  };

  # Age identities (SSH keys used for decryption)
  age.identityPaths = [
    "/Users/${config.system.primaryUser}/.ssh/id_ed25519"
    "/Users/${config.system.primaryUser}/.ssh/id_rsa"
  ];
}
