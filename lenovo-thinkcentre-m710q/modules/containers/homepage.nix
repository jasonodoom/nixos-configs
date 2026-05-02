# Homepage dashboard container configuration
{ config, pkgs, lib, ... }:

let
  # Homepage configuration variables
  containerIP = "192.168.100.50";
  hostIP = "192.168.100.1";
  httpPort = 3000;

  # Next.js configuration. Restrict allowedOrigins to the explicit known
  # access paths (LAN IP, container IP, localhost) instead of the '*'
  # wildcard, which permitted server-action requests from any origin.
  nextConfig = pkgs.writeTextFile {
    name = "next.config.js";
    text = ''
      module.exports = {
        experimental: {
          serverActions: {
            allowedOrigins: [
              'localhost:3000',
              '${containerIP}:${toString httpPort}',
              '192.168.1.42:3001',
              'congo',
            ],
          },
        },
      }
    '';
  };

  # Homepage configuration files
  homepageConfig = pkgs.writeTextDir "config/settings.yaml" ''
    title: Congo Server Dashboard
    favicon: https://github.com/walkxcode.png
    theme: dark
    color: slate
    target: _self

    headerStyle: boxed
    hideVersion: true

    layout:
      Security:
        style: row
        columns: 3
      Services:
        style: row
        columns: 3
      Monitoring:
        style: row
        columns: 2
  '';

  homepageServices = pkgs.writeTextDir "config/services.yaml" ''
    - Security:
        - OpenBao:
            href: http://192.168.1.42:8200
            description: Secrets Management
            icon: vault.png
            ping: http://192.168.100.10:8200

        - Pi-hole:
            href: http://192.168.1.42:8053
            description: DNS & Ad Blocking
            icon: pi-hole.png
            ping: http://192.168.100.42:80

        - OpenVPN:
            href: https://192.168.1.42:443
            description: VPN Server
            icon: openvpn.png

    - Services:
        - Tailscale:
            href: http://100.64.0.1:41641
            description: Mesh VPN
            icon: tailscale.png

        - FreeDNS:
            href: https://freedns.afraid.org
            description: Dynamic DNS
            icon: mdi-dns

    - Monitoring:
        - Loki Logs:
            href: http://192.168.1.42:8080/logs/
            description: Log Aggregation
            icon: grafana-loki.png
            ping: http://192.168.1.42:8080

        - Fail2ban:
            href: ssh://192.168.1.42:2222
            description: Intrusion Prevention
            icon: mdi-shield-lock
  '';

  homepageBookmarks = pkgs.writeTextDir "config/bookmarks.yaml" ''
    - Network:
        - Router:
            - icon: mdi-router
              href: http://192.168.1.1

        - UniFi Controller:
            - icon: mdi-access-point
              href: https://192.168.1.10:8443
  '';

  homepageWidgets = pkgs.writeTextDir "config/widgets.yaml" ''
    - greeting:
        text_size: xl
        text: "Congo Server"

    - datetime:
        text_size: l
        format:
          dateStyle: short
          timeStyle: short
          hourCycle: h23
  '';
in
{
  # Homepage dashboard container
  containers.homepage = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = hostIP;
    localAddress = containerIP;

    config = { config, pkgs, ... }: {
      system.stateVersion = "25.05";

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ httpPort ];
      };

      # Install Homepage
      environment.systemPackages = with pkgs; [
        homepage-dashboard
      ];

      # Homepage service
      systemd.services.homepage = {
        description = "Homepage Dashboard";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        serviceConfig = {
          Type = "simple";
          User = "homepage";
          Group = "homepage";
          ExecStart = "${pkgs.homepage-dashboard}/bin/homepage";
          Restart = "on-failure";
          RestartSec = 10;
          WorkingDirectory = "/var/lib/homepage";

          # Environment variables
          Environment = [
            "PORT=${toString httpPort}"
            "HOSTNAME=0.0.0.0"
            "HOMEPAGE_CONFIG_DIR=/var/lib/homepage/config"
            "NODE_ENV=production"
            "LOG_LEVEL=debug"
            "HOMEPAGE_VAR_TITLE=Congo Server"
            "HOMEPAGE_VAR_SEARCH_PROVIDER=duckduckgo"
            "HOMEPAGE_ALLOWED_HOSTS=192.168.1.42:3001,localhost:3000,0.0.0.0:3000"
          ];
        };

        preStart = ''
          # Create config directory
          mkdir -p /var/lib/homepage/config

          # Copy configuration files
          cp -f ${homepageConfig}/config/* /var/lib/homepage/config/ 2>/dev/null || true
          cp -f ${homepageServices}/config/* /var/lib/homepage/config/ 2>/dev/null || true
          cp -f ${homepageBookmarks}/config/* /var/lib/homepage/config/ 2>/dev/null || true
          cp -f ${homepageWidgets}/config/* /var/lib/homepage/config/ 2>/dev/null || true

          # Copy Next.js config to disable host validation
          cp -f ${nextConfig} /var/lib/homepage/next.config.js

          # Set permissions
          chown -R homepage:homepage /var/lib/homepage
          chmod -R 755 /var/lib/homepage
        '';
      };

      # Create homepage user
      users.users.homepage = {
        isSystemUser = true;
        group = "homepage";
        home = "/var/lib/homepage";
        createHome = true;
      };
      users.groups.homepage = {};

      # Create directories with proper permissions
      systemd.tmpfiles.rules = [
        "d /var/lib/homepage 0755 homepage homepage"
        "d /var/lib/homepage/config 0755 homepage homepage"
      ];
    };
  };

  # Host firewall: allow access to homepage on LAN
  networking.firewall.interfaces."enp0s31f6".allowedTCPPorts = [ 3001 ];

  # NAT forwarding for homepage
  networking.nat.forwardPorts = [
    {
      destination = "${containerIP}:${toString httpPort}";
      proto = "tcp";
      sourcePort = 3001;
    }
  ];

  # Note: Access homepage at http://192.168.1.42:3001
}
