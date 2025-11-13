# Fail2ban intrusion prevention system
{ config, pkgs, lib, ... }:

let
  # Fail2ban configuration variables
  sshPort = 2222;
  openvpnPort = 443;
  piholeHttpPort = 80;
  piholeHttpsPort = 443;
  openbaoPort = 8200;

  defaultBanTime = "24h";
  maxBanTime = "168h";
  sshMaxRetry = 3;
  vpnMaxRetry = 3;
  webMaxRetry = 5;
  defaultFindTime = "1h";
  webFindTime = "10m";

  trustedNetworks = "127.0.0.0/8 172.16.0.0/12 192.168.0.0/16";
in
{
  services.fail2ban = {
    enable = true;
    packageFirewall = pkgs.iptables;
    bantime = defaultBanTime;
    bantime-increment = {
      enable = true;
      maxtime = maxBanTime;
      factor = "2";
      rndtime = "10m";
    };

    jails = {
      sshd = {
        settings = {
          enabled = true;
          port = toString sshPort;
          filter = "sshd";
          backend = "systemd";
          maxretry = sshMaxRetry;
          bantime = defaultBanTime;
          findtime = defaultFindTime;
          ignoreip = trustedNetworks;
          action = "iptables-multiport[name=SSH, port=${toString sshPort}, protocol=tcp]";
        };
      };

      openvpn = {
        settings = {
          enabled = true;
          filter = "openvpn";
          backend = "systemd";
          journalmatch = "_SYSTEMD_UNIT=openvpn.service";
          maxretry = vpnMaxRetry;
          bantime = defaultBanTime;
          findtime = defaultFindTime;
          action = "iptables-multiport[name=OpenVPN, port=${toString openvpnPort}, protocol=tcp]";
        };
      };

      # Protect Pi-hole web interface
      pihole-web = {
        settings = {
          enabled = true;
          filter = "apache-auth";
          backend = "systemd";
          journalmatch = "_SYSTEMD_UNIT=pihole-FTL.service";
          maxretry = webMaxRetry;
          bantime = "1h";
          findtime = webFindTime;
          ignoreip = trustedNetworks;
          action = "iptables-multiport[name=PiHole-Web, port=${toString piholeHttpPort}, protocol=tcp]";
        };
      };

      # Protect OpenBao web interface
      openbao-web = {
        settings = {
          enabled = true;
          filter = "apache-auth";
          backend = "systemd";
          maxretry = vpnMaxRetry;
          bantime = defaultBanTime;
          findtime = defaultFindTime;
          ignoreip = trustedNetworks;
          action = "iptables-multiport[name=OpenBao-Web, port=${toString openbaoPort}, protocol=tcp]";
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    fail2ban
  ];

  # Custom fail2ban filters
  environment.etc."fail2ban/filter.d/openvpn.conf".text = ''
    [Definition]
    failregex = ^.*: TLS Error: incoming packet authentication failed from \[AF_INET\]<HOST>:\d+$
                ^.*: TLS handshake failed from \[AF_INET\]<HOST>:\d+$
                ^.*: Fatal TLS error \(check_tls_errors_co\), restarting from \[AF_INET\]<HOST>:\d+$
    ignoreregex =
  '';


  # Fail2ban status monitoring script
  environment.etc."fail2ban/fail2ban-status.sh" = {
    mode = "0755";
    text = ''
      #!/bin/bash
      echo "=== Fail2ban Status ==="
      ${pkgs.fail2ban}/bin/fail2ban-client status

      echo -e "\n=== Active Jails ==="
      for jail in $(${pkgs.fail2ban}/bin/fail2ban-client status | grep "Jail list" | sed -E 's/^[^:]+:(.*)$/\1/' | sed 's/[[:space:]]//g' | sed 's/,/ /g'); do
          echo "--- $jail ---"
          ${pkgs.fail2ban}/bin/fail2ban-client status $jail
      done

      echo -e "\n=== Recent Bans (last 24h) ==="
      journalctl --since "24 hours ago" | grep -i "fail2ban.*ban" || echo "No recent bans"
    '';
  };
}