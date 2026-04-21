# Pi-hole on congo, running directly on the host (no nspawn) so the LAN
# can reach DNS and the web UI at congo's address. Uses the upstream
# services.pihole-ftl NixOS module.
{ config, pkgs, lib, ... }:

{
  # systemd-resolved binds 127.0.0.53:53 and would race with pihole-FTL.
  services.resolved.enable = lib.mkForce false;

  services.pihole-ftl = {
    enable = true;
    openFirewallDNS = true;
    openFirewallWebserver = true;

    # Embedded webserver (pihole-FTL v6+).
    webserverEnabled = true;

    settings = {
      dns = {
        upstreams = [ "1.1.1.1" "9.9.9.9" ];
        dnssec = true;
        cache_size = 10000;
        bogusPriv = true;
        domainNeeded = true;
      };

      webserver = {
        port = "80o,443os";
        interface.boxed = true;
      };

      misc.privacylevel = 0;
    };
  };

  # One-shot: set admin password from agenix after FTL comes up.
  # pihole-FTL's native option accepts a hashed password in pihole.toml,
  # but the simplest working path is to invoke `pihole setpassword` on
  # first start, keyed off the decrypted secret.
  systemd.services.pihole-admin-password = {
    description = "Set Pi-hole admin password from agenix secret";
    after = [ "pihole-FTL.service" ];
    wants = [ "pihole-FTL.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Give FTL a moment to create its state.
      sleep 5

      if [ -f "${config.age.secrets.pihole-admin-password.path}" ]; then
        PASS=$(cat "${config.age.secrets.pihole-admin-password.path}")
        ${pkgs.pihole}/bin/pihole setpassword "$PASS"
        echo "Pi-hole admin password applied from agenix"
      else
        echo "WARN: pihole-admin-password secret not present; skipping"
      fi
    '';
  };
}
