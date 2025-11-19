# Tailscale VPN configuration for Theophany
{ config, pkgs, lib, ... }:

{
  # Enable Tailscale service
  services.tailscale = {
    enable = true;
  };

  # System packages for Tailscale management
  environment.systemPackages = with pkgs; [
    tailscale
  ];

  # Basic Tailscale connection
  # Note: Initial authentication requires manual run of:
  #   tailscale up
  launchd.daemons.tailscale-autoconnect = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "-c"
        ''
          sleep 2
          status=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r .BackendState || echo "NeedsLogin")

          if [ "$status" = "Running" ]; then
            echo "Tailscale is running"
          elif [ "$status" = "NeedsLogin" ]; then
            echo "Tailscale needs authentication."
            echo "Please run: tailscale up"
          else
            echo "Tailscale status: $status"
          fi
        ''
      ];
      RunAtLoad = true;
      StandardOutPath = "/var/log/tailscale-autoconnect.log";
      StandardErrorPath = "/var/log/tailscale-autoconnect.log";
    };
  };
}
