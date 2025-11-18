# Agenix secrets management for theophany (macOS)
{ config, pkgs, lib, ... }:

{
  # Age encryption configuration
  # Secrets are decrypted at activation time and symlinked to /run/agenix/

  # age.secrets.openai-api-key = {
  #   file = ../secrets/openai-api-key.age;
  #   owner = config.system.primaryUser;
  #   group = "staff";
  #   mode = "0400";
  # };

  # Environment variable from secret
  # environment.systemPackages = [
  #   (pkgs.writeScriptBin "load-secrets" ''
  #     #!${pkgs.bash}/bin/bash
  #     export OPENAI_API_KEY=$(cat /run/agenix/openai-api-key)
  #   '')
  # ];

  # Age identities (SSH keys used for decryption)
  age.identityPaths = [
    "/Users/${config.system.primaryUser}/.ssh/id_ed25519"
    "/Users/${config.system.primaryUser}/.ssh/id_rsa"
  ];
}
