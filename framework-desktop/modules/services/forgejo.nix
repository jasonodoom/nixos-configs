{ config, pkgs, ... }:

{
  services.forgejo = {
    enable = true;

    # SQLite — no external database needed
    database.type = "sqlite3";

    settings = {
      server = {
        DOMAIN = "perdurabo.ussuri-elevator.ts.net";
        HTTP_ADDR = "127.0.0.1"; # Caddy reverse-proxies to localhost
        HTTP_PORT = 3000;
        ROOT_URL = "https://perdurabo.ussuri-elevator.ts.net/";
        SSH_PORT = 22;
      };

      service = {
        DISABLE_REGISTRATION = true; # Admin creates accounts only
      };

      session = {
        COOKIE_SECURE = true; # TLS via Caddy & Tailscale certs
      };

      actions = {
        ENABLED = true;
      };

      log = {
        LEVEL = "Info";
      };
    };

    lfs.enable = true;

    dump = {
      enable = true;
      interval = "04:30";
      type = "tar.zst";
    };
  };

  # Caddy reverse proxy with Tailscale HTTPS certs
  services.caddy = {
    enable = true;
    virtualHosts."perdurabo.ussuri-elevator.ts.net" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:3000
        tls /var/lib/tailscale/certs/perdurabo.ussuri-elevator.ts.net.crt /var/lib/tailscale/certs/perdurabo.ussuri-elevator.ts.net.key
      '';
    };
  };

  # Ensure Caddy can read Tailscale certs
  systemd.services.caddy.serviceConfig.ExecStartPre = "+${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/chmod 755 /var/lib/tailscale && ${pkgs.coreutils}/bin/chmod 750 /var/lib/tailscale/certs && ${pkgs.coreutils}/bin/chown root:caddy /var/lib/tailscale/certs && ${pkgs.coreutils}/bin/chown root:caddy /var/lib/tailscale/certs/*.key && ${pkgs.coreutils}/bin/chmod 640 /var/lib/tailscale/certs/*.key'";

  # Open HTTPS on Tailscale interface (replace old port 3000)
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 443 ];
  };
}
