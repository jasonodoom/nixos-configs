# Probe congo's pi-hole once a minute from here (congo hosts its own
# monitoring, so it can't report its own outage). Three consecutive
# failures open a GitHub issue. Needs secrets/gh-token.age
# (GH_TOKEN=<token>); without it the probe only logs to the journal.
{ config, pkgs, lib, ... }:
let
  pihole = "192.168.1.42";
  hasToken = builtins.pathExists ../../secrets/gh-token.age;
in
{
  age.secrets = lib.mkIf hasToken {
    gh-token.file = ../../secrets/gh-token.age;
  };

  systemd.services.congo-pihole-watchdog = {
    description = "Probe congo's Pi-hole; alert on sustained failure";
    path = [ pkgs.dnsutils pkgs.coreutils ] ++ lib.optional hasToken pkgs.gh;
    serviceConfig = {
      Type = "oneshot";
      User = "jason";
      Group = "users";
    } // lib.optionalAttrs hasToken {
      EnvironmentFile = config.age.secrets.gh-token.path;
    };
    script = ''
      state=/tmp/congo-pihole-watchdog.state
      fails=$(cat "$state" 2>/dev/null || echo 0)
      if dig +time=3 +tries=1 @${pihole} example.com > /dev/null 2>&1; then
        if [ "$fails" -ge 3 ]; then
          echo "Pi-hole recovered after $fails failed probes"
        fi
        echo 0 > "$state"
        exit 0
      fi
      fails=$((fails + 1))
      echo "$fails" > "$state"
      echo "Pi-hole probe failure $fails (dig @${pihole} timed out)"
      if [ "$fails" -eq 3 ]; then
        echo "ALERT: Pi-hole on congo unreachable for 3 consecutive probes"
        ${lib.optionalString hasToken ''
        gh issue create \
          --repo jasonodoom/nixos-configs \
          --title "Pi-hole on congo is DOWN ($(date +%Y-%m-%d\ %H:%M))" \
          --body "Perdurabo's watchdog: 3 consecutive DNS probe failures against ${pihole}.

        House-wide client DNS depends on this box (force-redirect). See
        homenet incidents/2026-08-30-congo-autoupgrade-wedge-dns-outage.md
        for the triage playbook (temp pfSense mitigations, LUKS unlock)." \
          --assignee jasonodoom || echo "gh issue creation failed"
        ''}
      fi
    '';
  };

  systemd.timers.congo-pihole-watchdog = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1min";
    };
  };
}
