# Tailscale VPN configuration for Perdurabo
{ config, pkgs, lib, ... }:

{
  # Enable Tailscale service
  services.tailscale = {
    enable = true;
    permitCertUid = "caddy";  # Allow Caddy to fetch HTTPS certificates
    extraSetFlags = [ "--operator=jason" ];  # Allow jason to control Tailscale
    extraUpFlags = [ "--ssh" "--advertise-routes=192.168.88.0/24" "--accept-routes" ];
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
  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.shell]
    enabled-extensions=['appindicatorsupport@rgcjonas.gmail.com']
  '';

  # Tailscale systray user service (runs as user, not root)
  systemd.user.services.tailscale-systray = lib.mkIf config.services.desktopManager.gnome.enable {
    description = "Tailscale system tray";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" "tailscaled.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.tailscale}/bin/tailscale systray";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

}
