# Caddy in front of pihole-FTL's embedded webserver. pihole-FTL serves the
# admin interface itself on localhost:8081 (set via services.pihole-web.ports);
# Caddy terminates TLS on 80/443 with a cert from its local internal CA and
# reverse-proxies to it. Avoids the nginx in services/logs.nix (which binds
# 127.0.0.1:8080 for the Loki dashboard).
{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;
    extraConfig = ''
      (pihole_backend) {
        reverse_proxy localhost:8081
      }

      https://192.168.1.42,
      https://pihole.home,
      https://congo,
      https://congo.ussuri-elevator.ts.net {
        tls internal
        import pihole_backend
      }

      http://192.168.1.42,
      http://pihole.home,
      http://congo,
      http://congo.ussuri-elevator.ts.net {
        redir https://{host}{uri} permanent
      }
    '';
  };
}
