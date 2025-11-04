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

  # SSH configuration
  services.openssh = {
    enable = true;
    ports = [ 666 ];
    settings = {
      X11Forwarding = true;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = true;
    };
    authorizedKeysFiles = [ ".ssh/authorized_keys" ];
    extraConfig = "AllowUsers jason";
  };

  # Enable SSH agent authentication
  security.pam.sshAgentAuth.enable = true;
  security.pam.services.sudo.sshAgentAuth = false;

  # Tailscale for VPN
  services.tailscale.enable = true;
}