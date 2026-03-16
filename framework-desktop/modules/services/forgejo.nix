{ config, pkgs, ... }:

{
  services.forgejo = {
    enable = true;

    # SQLite — no external database needed
    database.type = "sqlite3";

    settings = {
      server = {
        DOMAIN = "perdurabo";
        HTTP_ADDR = "100.105.92.54"; # Tailscale IP only
        HTTP_PORT = 3000;
        ROOT_URL = "http://perdurabo:3000/";
        SSH_PORT = 22;
      };

      service = {
        DISABLE_REGISTRATION = true; # Admin creates accounts only
      };

      session = {
        COOKIE_SECURE = false; # No TLS on Tailscale internal
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

  # Open Forgejo port only on Tailscale interface
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 3000 ];
  };
}
