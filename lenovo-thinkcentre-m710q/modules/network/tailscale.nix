# Tailscale configuration for Congo
{ config, pkgs, lib, ... }:

{
  # Enable Tailscale service
  services.tailscale = {
    enable = true;
    extraUpFlags = [ "--ssh" "--advertise-exit-node" "--advertise-routes=192.168.1.0/24" "--accept-routes" ];
  };

  # Ensure Tailscale always restarts on failure
  systemd.services.tailscaled.serviceConfig = {
    Restart = lib.mkForce "always";
    RestartSec = lib.mkForce "10s";
  };

  # Note: Firewall port configured in networking.nix

  # System packages for Tailscale management
  environment.systemPackages = with pkgs; [
    tailscale
  ];

}