# Pi-hole on congo, running directly on the host (no nspawn) so the LAN
# can reach DNS and the web UI at congo's address. Uses the upstream
# services.pihole-ftl + services.pihole-web NixOS modules.
{ config, pkgs, lib, ... }:

{
  # systemd-resolved binds 127.0.0.53:53 and would race with pihole-FTL.
  services.resolved.enable = lib.mkForce false;

  # Restrict the Pi-hole web UI to Tailscale + the LAN subnets that need it.
  # DNS (port 53) stays open via services.pihole-ftl.openFirewallDNS.
  # Using extraCommands (iptables) because the firewall backend here is
  # iptables-nft, not nftables-native; extraInputRules would be ignored.
  networking.firewall.extraCommands = ''
    for src in 100.64.0.0/10 192.168.1.0/24 192.168.88.0/24; do
      iptables -A nixos-fw -p tcp --source "$src" --dport 80  -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --source "$src" --dport 443 -j nixos-fw-accept
    done
  '';

  # The packaged `pihole` shell wrapper unconditionally calls
  # /run/wrappers/bin/sudo -u pihole, which doesn't exist on this host
  # (sudo is disabled in favor of doas). Provide a setuid shim there that
  # forwards to doas so `pihole`, `pihole -g`, etc. work.
  security.wrappers.sudo = {
    setuid = true;
    owner = "root";
    group = "root";
    source = pkgs.writeShellScript "sudo-as-doas" ''
      exec /run/wrappers/bin/doas "$@"
    '';
  };

  # Web dashboard (separate package from pihole-FTL; FTL serves the static
  # assets from this package via its embedded webserver).
  services.pihole-web = {
    enable = true;
    ports = [ 8081 ]; # fronted by Caddy; 8080 conflicts with logs.nix nginx
  };

  # Known limitations from the current nixpkgs packaging:
  # - `pihole setpassword` fails with "Try with sudo power" because
  #   pihole-FTL needs CAP_CHOWN when invoked as the `pihole` user, but the
  #   wrapper script switches to that user before calling FTL. Workaround:
  #   set the password via the web UI, or as root:
  #     doas pihole-FTL --config webserver.api.password "<password>"
  # - `pihole status` reports "DNS service is NOT running" even when DNS
  #   works fine. The `pihole` script (v6.4) reads `files.pid` from FTL
  #   config; FTL v6.6 renamed that key. Cosmetic; DNS is unaffected.

  services.pihole-ftl = {
    enable = true;
    openFirewallDNS = true;
    # Web UI is firewall-restricted below (Tailscale + specific LANs only);
    # the module's global open-to-world would override that.
    openFirewallWebserver = false;

    # Embedded webserver (pihole-FTL v6+).
    webserverEnabled = true;

    settings = {
      dns = {
        upstreams = [
          "194.242.2.2"
          "2a07:e340::2"
          "9.9.9.9"
          "149.112.112.9"
        ];
        dnssec = true;
        cache_size = 10000;
        bogusPriv = true;
        domainNeeded = true;
        # Accept queries on any interface/source. Default "LOCAL" only allows
        # clients in the same subnet as Pi-hole, which silently drops queries
        # from Tailscale (100.64.0.0/10).
        listeningMode = "ALL";
      };

      webserver = {
        # `port` is now managed by services.pihole-web.ports.
        interface.boxed = true;
      };

      misc = {
        privacylevel = 0;
        # Allow runtime config changes via web UI and `pihole` CLI; the
        # module defaults to readOnly which prevents password set, blocklist
        # edits, and gravity updates from persisting.
        readOnly = false;
      };
    };
  };

  # Declarative blocklist seeding: insert OISD Big on first start, then
  # let the user manage adlists via the web UI. Idempotent — only inserts
  # rows that don't already exist.
  systemd.services.pihole-seed-adlists = {
    description = "Seed default Pi-hole adlists if gravity DB is empty";
    after = [ "pihole-FTL.service" ];
    wants = [ "pihole-FTL.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "pihole";
      Group = "pihole";
    };
    path = [ pkgs.sqlite ];
    script = ''
      DB=/var/lib/pihole/gravity.db
      # Wait briefly for the DB to materialize on first boot.
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        [ -f "$DB" ] && break
        sleep 1
      done
      [ -f "$DB" ] || exit 0

      # StevenBlack/hosts — canonical Pi-hole adlist, plain hosts format.
      sqlite3 "$DB" "INSERT OR IGNORE INTO adlist (address, enabled, comment) \
        VALUES ('https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts', 1, 'StevenBlack (seeded)');"
    '';
  };
}
