# Tailscale configuration for Congo
{ config, pkgs, lib, ... }:

{
  # Enable Tailscale service
  services.tailscale.enable = true;

  # Ensure Tailscale always restarts on failure
  systemd.services.tailscale.serviceConfig = {
    Restart = "always";
    RestartSec = "10s";
  };

  # Note: Firewall port configured in networking.nix

  # System packages for Tailscale management
  environment.systemPackages = with pkgs; [
    tailscale
  ];

  # Configure as Tailscale exit node, subnet router and SSH
  # Note: Initial authentication requires manual run of:
  #   tailscale up --ssh --advertise-exit-node --advertise-routes=192.168.1.0/24 --accept-routes
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale with exit node, subnet router and SSH";
    after = [ "network-online.target" "tailscale.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      sleep 2
      status=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r .BackendState || echo "NeedsLogin")

      if [ "$status" = "Running" ]; then
        # Already authenticated, ensure all features are enabled
        echo "Tailscale is running, ensuring exit node, subnet router, and SSH are enabled..."
        ${pkgs.tailscale}/bin/tailscale set --advertise-exit-node --advertise-routes=192.168.1.0/24 --ssh
      elif [ "$status" = "NeedsLogin" ]; then
        # Needs authentication
        echo "Tailscale needs authentication."
        echo "Please run: doas tailscale up --ssh --advertise-exit-node --advertise-routes=192.168.1.0/24 --accept-routes"
        echo "Then approve the exit node and subnet routes in the Tailscale admin console."
      else
        echo "Tailscale status: $status"
      fi
    '';
  };
}