# Bash Aliases Configuration for Congo Server
{ config, pkgs, lib, ... }:

{
  programs.bash.shellAliases = {
    # Core commands
    "sudo" = "doas";
    "ll" = "ls -la";

    # System rebuild from nixos-configs repo
    "update-system" = "doas nixos-rebuild switch --flake 'git+ssh://git@github-deploy.com/jasonodoom/nixos-configs.git?dir=lenovo-thinkcentre-m710q&ref=main#congo' --refresh";

    # Server monitoring
    "ports" = "netstat -tuln";
    "banned" = "doas fail2ban-client status sshd";

    # Container management
    "containers" = "systemctl list-units 'container@*'";

    # AI agents in sandboxed nspawn containers
    "claude" = "ssh -qt agent@10.0.43.2 -p 2201 claude";
    "codex" = "ssh -qt agent@10.0.43.6 -p 2202 codex";
    "gemini" = "ssh -qt agent@10.0.43.10 -p 2203 gemini";

    # Container health checks (via HTTP)
    "check-openbao" = "curl -s http://localhost:8200/v1/sys/health";
    "check-pihole" = "curl -s http://localhost:8053";

    # Container logs (via journalctl)
    "pihole-logs" = "journalctl -u container@pihole -f";
    "openbao-logs" = "journalctl -u container@openbao -f";
    "openvpn-logs" = "journalctl -u container@openvpn -f";

    # Container shell access
    "pihole-shell" = "nixos-container run pihole -- /bin/bash";
    "openbao-shell" = "nixos-container run openbao -- /bin/bash";
    "openvpn-shell" = "nixos-container run openvpn -- /bin/bash";

    # Log dashboard and aggregated logs
    "logs" = "curl -s http://localhost:8080/logs";
    "logdash" = "echo 'Log dashboard: http://congo:8080/logs'";
    "recent-bans" = "journalctl -u fail2ban -n 20";
    "dns-logs" = "journalctl -u container@pihole -f";
    "syslog-tail" = "logcli query '{job=\"systemd-journal\"}' --tail --since=1h";
  };
}