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
    };
  };

  # SSH configuration moved to security.nix to avoid duplication

  # Tailscale for VPN
  services.tailscale.enable = true;
}