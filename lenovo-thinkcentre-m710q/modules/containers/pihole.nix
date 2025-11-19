# Pi-hole NixOS container configuration using unstable packages
{ config, pkgs, pkgs-unstable, lib, ... }:

let
  # Pi-hole configuration variables
  containerIP = "192.168.100.42";
  hostIP = "192.168.100.1";
  dnsPort = 53;
  httpPort = 80;
  httpsPort = 443;
  upstreamDNS1 = "1.1.1.1";
  upstreamDNS2 = "9.9.9.9";
  certCN = "pi.hole";

  # Use unstable packages for latest Pi-hole
  pihole-pkg = pkgs-unstable.pihole;
  pihole-ftl-pkg = pkgs-unstable.pihole-ftl;
  pihole-web-pkg = pkgs-unstable.pihole-web;
in
{
  # Pi-hole NixOS container
  containers.pihole = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = hostIP;
    localAddress = containerIP;

    # Bind mount the pihole admin password secret into container
    bindMounts = {
      "/run/secrets/pihole-admin-password" = {
        hostPath = config.age.secrets.pihole-admin-password.path;
        isReadOnly = true;
      };
    };

    config = { config, pkgs, ... }: {
      system.stateVersion = "25.05";

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ dnsPort httpPort httpsPort ];
        allowedUDPPorts = [ dnsPort ];
      };

      # Install Pi-hole packages from unstable
      environment.systemPackages = [
        pihole-pkg
        pihole-ftl-pkg
        pihole-web-pkg
      ] ++ (with pkgs; [
        curl
        wget
        sqlite
        nettools
        iproute2
      ]);

      # Pi-hole FTL (DNS server)
      systemd.services.pihole-FTL = {
        description = "Pi-hole FTL DNS Server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        serviceConfig = {
          Type = "simple";
          User = "pihole";
          Group = "pihole";
          ExecStart = "${pihole-ftl-pkg}/bin/pihole-FTL -f";
          Restart = "on-failure";
          RestartSec = 10;
          StartLimitBurst = 3;
          StartLimitIntervalSec = 60;
          StateDirectory = "pihole";
          ConfigurationDirectory = "pihole";
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        };

        preStart = ''
          # Clean up stale FTL shared memory files to prevent /dev/shm from filling
          rm -f /dev/shm/FTL-* 2>/dev/null || true

          # Fix database corruption issue (common in NixOS containers)
          if [ -f /var/lib/pihole/pihole-FTL.db ]; then
            # Check if database is corrupted or empty
            if ! ${pkgs.sqlite}/bin/sqlite3 /var/lib/pihole/pihole-FTL.db "SELECT name FROM sqlite_master LIMIT 1;" 2>/dev/null; then
              echo "Corrupted pihole-FTL.db detected, removing to recreate..."
              rm -f /var/lib/pihole/pihole-FTL.db*
            elif [ ! -s /var/lib/pihole/pihole-FTL.db ]; then
              echo "Empty pihole-FTL.db detected, removing to recreate..."
              rm -f /var/lib/pihole/pihole-FTL.db*
            fi
          fi

          # Set admin password from age secret
          if [ -f /run/secrets/pihole-admin-password ]; then
            # Copy secret to temp location that pihole user can access
            ADMIN_PASS=$(cat /run/secrets/pihole-admin-password 2>/dev/null || echo "")
            if [ -n "$ADMIN_PASS" ]; then
              echo "WEBPASSWORD=$ADMIN_PASS" > /etc/pihole/setupVars.conf
              chown pihole:pihole /etc/pihole/setupVars.conf
              chmod 644 /etc/pihole/setupVars.conf
            else
              echo "Warning: Could not read pihole admin password from secret"
            fi
          fi

          # Create pihole.toml configuration for web interface
          echo "Setting up Pi-hole TOML config..."
          cat > /etc/pihole/pihole.toml << EOF
[database]
dbfile = "/var/lib/pihole/pihole-FTL.db"

[webserver]
port = ${toString httpPort}
bind = "0.0.0.0"

[webserver.api.allow_destructive]
gravity = true
flush_network_table = true
flush_arp_table = true

[logging]
level = "info"
destination = "file"
file = "/var/log/pihole/pihole.log"

[network]
interface = "eth0"

[dns]
dnssec = true
cache_size = 10000
EOF
          chown pihole:pihole /etc/pihole/pihole.toml
          echo "Pi-hole TOML config written to /etc/pihole/pihole.toml"

          # Basic Pi-hole configuration
          echo "Setting up Pi-hole FTL config..."
          cat > /etc/pihole/pihole-FTL.conf << EOF
PIHOLE_DNS_1=${upstreamDNS1}
PIHOLE_DNS_2=${upstreamDNS2}
DNS_FQDN_REQUIRED=true
DNS_BOGUS_PRIV=true
DNSSEC=true
CONDITIONAL_FORWARDING=false
BLOCKING_ENABLED=true
EOF
          chown pihole:pihole /etc/pihole/pihole-FTL.conf
          echo "Pi-hole FTL config written to /etc/pihole/pihole-FTL.conf"
        '';
      };


      # Create pihole user
      users.users.pihole = {
        isSystemUser = true;
        group = "pihole";
        home = "/var/lib/pihole";
        createHome = true;
      };
      users.groups.pihole = {};

      # Allow pihole user to run pihole commands without password
      # This allows the web interface to trigger gravity updates
      security.doas = {
        enable = true;
        extraRules = [
          {
            users = [ "pihole" ];
            noPass = true;
            cmd = "${pihole-pkg}/bin/pihole";
          }
        ];
      };

      # Create directories with proper permissions
      systemd.tmpfiles.rules = [
        "d /etc/pihole 0755 pihole pihole"
        "d /var/log/pihole 0755 pihole pihole"
        "d /var/lib/pihole 0755 pihole pihole"
        "d /var/www 0755 root root"
        "L+ /var/www/html - - - - ${pihole-web-pkg}/share"
        "L+ /usr/local/bin/pihole - - - - ${pihole-pkg}/bin/pihole"
      ];

      # Pi-hole blocklist management
      systemd.services.pihole-gravity = {
        description = "Update Pi-hole gravity (blocklists)";
        serviceConfig = {
          Type = "oneshot";
          User = "pihole";
          Group = "pihole";
        };
        script = ''
          ${pihole-pkg}/bin/pihole updateGravity
        '';
      };

      systemd.timers.pihole-gravity = {
        description = "Update Pi-hole gravity daily";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };

      # Set Pi-hole password from secret after FTL starts
      systemd.services.pihole-set-password = {
        description = "Set Pi-hole admin password from secret";
        after = [ "pihole-FTL.service" ];
        wants = [ "pihole-FTL.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # Wait for FTL to be fully started
          sleep 5

          # Set password if secret exists
          if [ -f /run/secrets/pihole-admin-password ]; then
            ADMIN_PASS=$(cat /run/secrets/pihole-admin-password)
            ${pihole-pkg}/bin/pihole setpassword "$ADMIN_PASS"
            echo "Pi-hole admin password set from secret"
          else
            echo "Warning: No Pi-hole admin password secret found"
          fi
        '';
      };
    };
  };

  # Note: Host firewall rules and NAT forwarding configured in networking.nix
}