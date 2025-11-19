# Tailscale VPN configuration for Perdurabo
{ config, pkgs, lib, ... }:

{
  # Enable Tailscale service
  services.tailscale = {
    enable = true;
    permitCertUid = "caddy";  # Allow Caddy to fetch HTTPS certificates
    extraSetFlags = [ "--operator=jason" ];  # Allow jason to control Tailscale
  };

  # Automatic Tailscale certificate renewal
  systemd.services.tailscale-cert-renewal = {
    description = "Renew Tailscale HTTPS certificates";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.tailscale}/bin/tailscale cert perdurabo.ussuri-elevator.ts.net";
    };
  };

  systemd.timers.tailscale-cert-renewal = {
    description = "Renew Tailscale HTTPS certificates monthly";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  # Ensure Tailscale always restarts on failure
  systemd.services.tailscaled.serviceConfig = {
    Restart = lib.mkForce "always";
    RestartSec = lib.mkForce "10s";
  };

  # System packages for Tailscale management
  environment.systemPackages = with pkgs; [
    tailscale
    wl-clipboard  # Required for clipboard support in Tailscale systray
  ];

  # Enable GNOME AppIndicator extension for Tailscale systray
  services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.shell]
    enabled-extensions=['appindicatorsupport@rgcjonas.gmail.com']
  '';

  # Tailscale systray user service (runs as user, not root)
  systemd.user.services.tailscale-systray = lib.mkIf config.services.xserver.desktopManager.gnome.enable {
    description = "Tailscale system tray";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" "tailscaled.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.tailscale}/bin/tailscale systray";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Configure as Tailscale subnet router with SSH
  # Note: Initial authentication requires manual run of:
  #   tailscale up --ssh --advertise-routes=192.168.88.0/24 --accept-routes
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale with subnet router and SSH";
    after = [ "network-online.target" "tailscaled.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      sleep 2
      status=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r .BackendState || echo "NeedsLogin")

      if [ "$status" = "Running" ]; then
        # Already authenticated, ensure subnet router and SSH are enabled
        echo "Tailscale is running, ensuring subnet router and SSH are enabled..."
        ${pkgs.tailscale}/bin/tailscale set --advertise-routes=192.168.88.0/24 --ssh
      elif [ "$status" = "NeedsLogin" ]; then
        # Needs authentication
        echo "Tailscale needs authentication."
        echo "Please run: doas tailscale up --ssh --advertise-routes=192.168.88.0/24 --accept-routes"
        echo "Then approve the subnet routes in the Tailscale admin console."
      else
        echo "Tailscale status: $status"
      fi
    '';
  };
}
