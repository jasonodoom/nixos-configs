# Networking configuration
{ config, pkgs, lib, ... }:

{
  networking = {
    # Use NetworkManager for easier wireless management
    networkmanager.enable = true;
    useDHCP = false;

    # Static IP configuration
    interfaces = {
      # Set static IP for primary ethernet interface
      enp0s25.ipv4.addresses = [ {
        address = "192.168.88.5";
        prefixLength = 24;
      } ];
    };

    # Default gateway
    defaultGateway = "192.168.88.1";

    # DNS configuration
    nameservers = [ "1.1.1.1" "9.9.9.9" ];

    # Firewall
    firewall = {
      enable = true;
      allowPing = false;
      allowedTCPPorts = [ 6666 ]; # SSH port
      checkReversePath = "loose";
    };
  };

  # Enable IP forwarding for Tailscale subnet routing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
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

  # SSH configuration moved to security.nix to avoid duplication
  # Tailscale configuration moved to tailscale.nix
}