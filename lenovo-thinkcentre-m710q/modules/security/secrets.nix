{ config, pkgs, lib, ... }:

{
  # Import agenix secrets
  age = {
    secrets = {
      # User password for login
      amy-password = {
        file = ../../secrets/amy-password.age;
        owner = "amy";
        group = "users";
        mode = "0400";
      };

      # Initrd SSH host key for remote LUKS unlock
      initrd-ssh-host-key = {
        file = ../../secrets/initrd-ssh-host-ed25519-key.age;
        path = "/etc/ssh/initrd_ssh_host_ed25519_key";
        mode = "0600";
      };

      # Pi-hole admin password
      pihole-admin-password = {
        file = ../../secrets/pihole-admin-password.age;
        mode = "0400";
      };

      # Tailscale auth key for initrd remote LUKS unlock
      tailscale-initrd-key = {
        file = ../../secrets/tailscale-initrd-key.age;
        mode = "0400";
      };
    };

    # Use the system's SSH host key for decryption
    identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
