# Networking configuration
{ config, pkgs, lib, ... }:

{
  networking = {
    # Use NetworkManager for easier wireless management
    networkmanager.enable = true;
    useDHCP = false;

    # DNS configuration
    nameservers = [ "1.1.1.1" "8.8.8.8" ];

    # Firewall
    firewall = {
      enable = true;
      allowPing = false;
      allowedTCPPorts = [ 666 ]; # SSH port
    };
  };

  # SSH configuration moved to security.nix to avoid duplication

  # Tailscale for VPN
  services.tailscale.enable = true;
}