{ config, pkgs, lib, ... }:

{
  # Import agenix secrets
  age = {
    secrets = {
      # User password for login
      jason-password = {
        file = ../../secrets/jason-password.age;
        owner = "jason";
        group = "users";
        mode = "0400";
      };
    };

    # Use the system's SSH host key for decryption
    identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

}
