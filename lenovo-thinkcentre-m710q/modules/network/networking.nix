# Networking configuration for Congo server
{ config, pkgs, lib, ... }:

{
  networking = {
    # Use NetworkManager for easier management
    networkmanager.enable = true;
    useDHCP = false;

    # DHCP configuration for LAN
    interfaces = {
      enp0s31f6.useDHCP = true;
    };

    # DNS configuration (fallback if DHCP doesn't provide)
    nameservers = [ "1.1.1.1" "9.9.9.9" ];

    # Firewall configuration
    firewall = {
      enable = true;
      allowPing = false;
      allowedTCPPorts = [
        2222  # SSH
        53    # Pi-hole DNS
      ];
      allowedUDPPorts = [
        53     # Pi-hole DNS
        41641  # Tailscale
      ];
      interfaces."enp0s31f6" = {
        allowedTCPPorts = [
          80    # Direct HTTP (if any)
          8053  # Pi-hole HTTP (192.168.100.42:80)
          8443  # Pi-hole HTTPS (192.168.100.42:443)
          8200  # OpenBao (192.168.100.10:8200)
          8080  # Logs dashboard
          3100  # Loki API
        ];
      };
      # Disable reverse path filtering for containers
      checkReversePath = "loose";
    };

    # Container networking
    nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "enp0s31f6";

      # Port forwarding for container services
      forwardPorts = [
        # Pi-hole DNS (TCP & UDP)
        {
          sourcePort = 53;
          destination = "192.168.100.42:53";
          proto = "tcp";
        }
        {
          sourcePort = 53;
          destination = "192.168.100.42:53";
          proto = "udp";
        }
        # Pi-hole web interface (HTTP)
        {
          sourcePort = 8053;
          destination = "192.168.100.42:80";
          proto = "tcp";
        }
        # Pi-hole web interface (HTTPS)
        {
          sourcePort = 8443;
          destination = "192.168.100.42:443";
          proto = "tcp";
        }
        # OpenBao
        {
          sourcePort = 8200;
          destination = "192.168.100.10:8200";
          proto = "tcp";
        }
      ];
    };

  };

  # Enable required kernel modules for container networking
  boot.kernelModules = [ "bridge" "br_netfilter" ];

  # Enable IP forwarding for containers and VPN
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    # Fix container inter-communication (bridge netfilter)
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.bridge.bridge-nf-call-ip6tables" = 1;
    "net.bridge.bridge-nf-call-arptables" = 1;
  };

  # Enable UDP GRO forwarding for Tailscale performance
  # https://tailscale.com/s/ethtool-config-udp-gro
  systemd.services.tailscale-udp-gro = {
    description = "Enable UDP GRO forwarding for Tailscale";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      NETDEV=$(${pkgs.iproute2}/bin/ip -o route get 8.8.8.8 | cut -f 5 -d " ")
      ${pkgs.ethtool}/bin/ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off || true
    '';
  };

  # Container NAT networking - remove bridge attachment for NAT to work
  systemd.services.container-nat-fix = {
    description = "Ensure container interfaces not attached to bridge for NAT";
    wantedBy = [ "multi-user.target" ];
    after = [ "containers.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Wait for container interfaces
      sleep 5

      # Remove bridge attachment for NAT networking to work
      ${pkgs.iproute2}/bin/ip link set ve-openbao nomaster 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip link set ve-pihole nomaster 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip link set ve-homepage nomaster 2>/dev/null || true
    '';
  };
}